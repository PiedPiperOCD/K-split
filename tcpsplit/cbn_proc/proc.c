#include <linux/init.h>      // included for __init and __exit macros
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/slab.h>

#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/string.h>

//#include <linux/kthread.h>
//#include <linux/sched.h>

//#include <linux/printk.h>
//
static int cbn_proc_show(struct seq_file *m, void *v)
{
	seq_printf(m, "Hello proc!\n");
	return 0;
}

static int cbn_proc_open(struct inode *inode, struct  file *file)
{
	return single_open(file, cbn_proc_show, NULL);
}

#define PROC_CSV_NUM 2
static ssize_t cbn_proc_command(struct file *file, const char __user *buf,
				    size_t size, loff_t *_pos)
{
	char *kbuf;
	int   values[PROC_CSV_NUM + 1] = {0};


	/* start by dragging the command into memory */
	if (size <= 1 || size >= PAGE_SIZE)
		return -EINVAL;

	kbuf = memdup_user_nul(buf, size);
	if (IS_ERR(kbuf))
		return PTR_ERR(kbuf);


	get_options(kbuf, ARRAY_SIZE(values), values);

	kfree(kbuf);
	return (values[0]) ? size : -EINVAL;
}

static const struct file_operations cbn_proc_fops = {
	.owner		= THIS_MODULE,
	.open		= cbn_proc_open,
	.read 		= seq_read,
	.write		= cbn_proc_command,
	.llseek 	= seq_lseek,
	.release 	= single_release,
};

static struct proc_dir_entry *cbn_dir;

static int __init cbn_proc_init(void)
{
	cbn_dir = proc_mkdir_mode("cbn", 00555, NULL);
	proc_create("cbn_proc", 00666, cbn_dir, &cbn_proc_fops);
	return 0;
}

static void __exit cbn_proc_clean(void)
{
	remove_proc_subtree("cbn", NULL);
}

module_init(cbn_proc_init);
module_exit(cbn_proc_clean);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Anonymous");
MODULE_DESCRIPTION("Proc iface");

