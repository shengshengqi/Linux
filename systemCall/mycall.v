//此处的空格应该使用Tab建
335     common  ssqsetnice              __x64_sys_ssqsetnice

asmlinkage long sys_ssqsetnice(pid_t pid,int flag,int nicevalue,void __user * prio,void __user * nice);

SYSCALL_DEFINE5(ssqsetnice,pid_t,pid,int,flag,int,nicevalue,void __user *,prio,void __user *,nice)
{
        int priob;
        int niceb;
        int nicen;
        int prion;
        struct pid * spid;
        struct task_struct * task;
        spid = find_get_pid(pid);
        task = pid_task(spid, PIDTYPE_PID);
        niceb = task_nice(task);
        priob = task_prio(task);

        if(flag == 1){
                set_user_nice(task, nicevalue);
                nicen = task_nice(task);
                prion = task_prio(task);
                copy_to_user(prio,(const void*)&prion, sizeof(prion));
                copy_to_user(nice,(const void*)&nicen, sizeof(nicen));
                return 0;
        }
        else if(flag == 0){
                copy_to_user(prio, (const void*)&priob, sizeof(priob));
                copy_to_user(nice, (const void*)&niceb, sizeof(niceb));
                return 0;
        }

        return EFAULT;
}
