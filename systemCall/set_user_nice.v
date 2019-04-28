void set_user_nice(struct task_struct *p, long nice) //用于修改nice值
{
	bool queued, running; //布尔类型的两个变量，分别用于记录就绪状态、运行状态
	int old_prio, delta; //记录旧的优先级、优先级的差值
	struct rq_flags rf; //就绪队列运行标志
	struct rq *rq;  //CPU就绪队列

	if (task_nice(p) == nice || nice < MIN_NICE || nice > MAX_NICE)	//判断nice值是否变化，或者超出-20~19的范围
		return;
	/*
	 * We have to be careful, if called from sys_setpriority(),
	 * the task might be in the middle of scheduling on another CPU.
	 */
	rq = task_rq_lock(p, &rf); //锁住队列
	update_rq_clock(rq);	//更新队列时钟

	/*
	 * The RT priorities are set via sched_setscheduler(), but we still
	 * allow the 'normal' nice value to be set - but as expected
	 * it wont have any effect on scheduling until the task is
	 * SCHED_DEADLINE, SCHED_FIFO or SCHED_RR:
	 */
	if (task_has_dl_policy(p) || task_has_rt_policy(p)) { //实时进程
		p->static_prio = NICE_TO_PRIO(nice);	//nice+120
		goto out_unlock; //解锁
	}
	/*实时进程基于静态优先级进行调度，其权值（=1000+静态优先级）将始终大于普通进程，
	因此只有在就绪队列中没有实时进程的时候，普通进程才能得到调度。*/
	queued = task_on_rq_queued(p);	//判断是否在就绪队列
	running = task_current(rq, p);	//判断是否在运行状态
	if (queued)
		dequeue_task(rq, p, DEQUEUE_SAVE | DEQUEUE_NOCLOCK);	//将进程从就绪队列取出
	if (running)
		put_prev_task(rq, p);	//用另一个进程代替当前运行的进程之前调用,将切换出去的进程插入到队尾

	p->static_prio = NICE_TO_PRIO(nice);	//nice+120
	set_load_weight(p, true); //重新计算权重
	old_prio = p->prio;
	p->prio = effective_prio(p);	//重新计算动态优先级Prio = max(100,min(static_prio-bonus+5,139)),
									//bonus取决于进程的平均睡眠时间，平均睡眠时间越长，bonus越大
	delta = p->prio - old_prio;	//优先级的差值

	if (queued) {
		enqueue_task(rq, p, ENQUEUE_RESTORE | ENQUEUE_NOCLOCK);	//将进程添加到就绪队列中
		/*
		 * If the task increased its priority or is running and
		 * lowered its priority, then reschedule its CPU:
		 */
		if (delta < 0 || (delta > 0 && task_running(rq, p)))
			resched_curr(rq);	//设置调度标志，判断是否需要抢占
	}
	if (running)
		set_curr_task(rq, p);//如果调度策略发生变化，调用此函数修改cpu当前的task
out_unlock:
	task_rq_unlock(rq, p, &rf);	//解锁
}
EXPORT_SYMBOL(set_user_nice);