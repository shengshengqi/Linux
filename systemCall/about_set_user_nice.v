void update_rq_clock(struct rq *rq)
{
	s64 delta;	//typedef long long		s64;

	lockdep_assert_held(&rq->lock);	/*#define lockdep_assert_held(l)	do {	
									WARN_ON(debug_locks && !lockdep_is_held(l));
									} while (0)
									#define lockdep_assert_held(l)			do { (void)(l); } while (0)
									没看懂这个定义，百度查到的功能是：检查当前进程是否已经设置了调度标志*/

	if (rq->clock_update_flags & RQCF_ACT_SKIP) //#define RQCF_ACT_SKIP		0x02
		return;

#ifdef CONFIG_SCHED_DEBUG
	if (sched_feat(WARN_DOUBLE_CLOCK))
		SCHED_WARN_ON(rq->clock_update_flags & RQCF_UPDATED);
	rq->clock_update_flags |= RQCF_UPDATED;
#endif

	delta = sched_clock_cpu(cpu_of(rq)) - rq->clock;
	if (delta < 0)
		return;
	rq->clock += delta;
	update_rq_clock_task(rq, delta);
}
//太复杂了，就不往里看了

static inline int task_has_dl_policy(struct task_struct *p)
{
	return dl_policy(p->policy);	//policy，本进程采用的调度策略。Linux支持6种调度策略,将调度策略设置为dl
}

static inline int dl_policy(int policy)	
{
	return policy == SCHED_DEADLINE;	//#define SCHED_DEADLINE		6
}

/*
 * Scheduling policies
 */
#define SCHED_NORMAL		0	//用于普通进程，由fair_sched_class调度器类来处理
#define SCHED_FIFO		1	//用于软实时进程，采用先进先出算法，由实时调度器rt_sched_class调度器类处理。
#define SCHED_RR		2	//用于软实时进程，采用时间片轮转算法，由实时调度器rt_sched_class调度器类处理。
#define SCHED_BATCH		3	//通过fair_sched_class调度器类来处理，用于非交互式且CPU密集型的批处理进程
/* SCHED_ISO: reserved but not implemented yet */
#define SCHED_IDLE		5	//由idle_sched_class调度器来处理，相对权重总是最小，用于调度系统闲散时才运行的进程。
#define SCHED_DEADLINE		6	//新支持的实时进程调度策略，针对突发型计算且对延迟和完成时间高度敏感的任务试用，基于First调度算法，有dl_sched_class

static inline int task_on_rq_queued(struct task_struct *p)	//判断是否在就绪队列
{
	return p->on_rq == TASK_ON_RQ_QUEUED; //#define TASK_ON_RQ_QUEUED 	1
}

static inline int task_current(struct rq *rq, struct task_struct *p)
{
	return rq->curr == p;	//curr指针指向当前正在运行的指针
}

static inline void dequeue_task(struct rq *rq, struct task_struct *p, int flags)
{
	if (!(flags & DEQUEUE_NOCLOCK)) //#define DEQUEUE_NOCLOCK		0x08 /* Matches ENQUEUE_NOCLOCK */
		update_rq_clock(rq);

	if (!(flags & DEQUEUE_SAVE)) {	//#define DEQUEUE_SAVE		0x02 /* Matches ENQUEUE_RESTORE */
		sched_info_dequeued(rq, p);	
		psi_dequeue(p, flags & DEQUEUE_SLEEP);
	}

	p->sched_class->dequeue_task(rq, p, flags);
}

/*太复杂了
static inline void sched_info_dequeued(struct rq *rq, struct task_struct *t)
{
	unsigned long long now = rq_clock(rq), delta = 0;

	if (unlikely(sched_info_on()))
		if (t->sched_info.last_queued)
			delta = now - t->sched_info.last_queued;
	sched_info_reset_dequeued(t);
	t->sched_info.run_delay += delta;

	rq_sched_info_dequeued(rq, delta);
}

static inline u64 rq_clock(struct rq *rq)
{
	lockdep_assert_held(&rq->lock);
	assert_clock_updated(rq);

	return rq->clock;
}
*/
static inline void put_prev_task(struct rq *rq, struct task_struct *prev)
{
	prev->sched_class->put_prev_task(rq, prev);	//递归将该进程放到队尾，所有其他进程前移一位
}

#define NICE_TO_PRIO(nice)	((nice) + DEFAULT_PRIO)
#define DEFAULT_PRIO		(MAX_RT_PRIO + NICE_WIDTH / 2)
#define MAX_RT_PRIO		MAX_USER_RT_PRIO
#define MAX_USER_RT_PRIO	100
#define MAX_NICE	19
#define MIN_NICE		-20
#define NICE_WIDTH	(MAX_NICE - MIN_NICE + 1)

static void set_load_weight(struct task_struct *p, bool update_load)
{
	int prio = p->static_prio - MAX_RT_PRIO;
	struct load_weight *load = &p->se.load;

	/*
	 * SCHED_IDLE tasks get minimal weight:
	 */
	if (idle_policy(p->policy)) {	//相对权重总是最小，用于调度系统闲散时才运行的进程
		load->weight = scale_load(WEIGHT_IDLEPRIO);	//#define WEIGHT_IDLEPRIO		3
		load->inv_weight = WMULT_IDLEPRIO;	//#define WMULT_IDLEPRIO		1431655765
		p->se.runnable_weight = load->weight;
		return;
	}

	/*
	 * SCHED_OTHER tasks have to update their load when changing their
	 * weight
	 */
	if (update_load && p->sched_class == &fair_sched_class) {	//判断是否是完全公平调度类，重新计算权重
		reweight_task(p, prio);
	} else {
		load->weight = scale_load(sched_prio_to_weight[prio]);	//sched_load(w)如果有标志位，则权重无符号左移# define SCHED_FIXEDPOINT_SHIFT		10
																//如果没有，权重就是w。
																//sched_prio_to_weight[prio]是一个有40个数的数组
		load->inv_weight = sched_prio_to_wmult[prio];			//sched_prio_to_wmult[prio]是一个有40个数的数组（预先计算、加快计算速度）
																//inv_weight存储了权重值用于重除的结果
		p->se.runnable_weight = load->weight;					
	}
}

static inline int idle_policy(int policy)
{
	return policy == SCHED_IDLE;	//#define SCHED_IDLE		5
}

static int effective_prio(struct task_struct *p)
{
	p->normal_prio = normal_prio(p);	//根据调度策略重新计算常规动态优先级
	/*
	 * If we are RT tasks or we were boosted to RT priority,
	 * keep the priority unchanged. Otherwise, update priority
	 * to the normal priority:
	 */
	if (!rt_prio(p->prio))	//如果是普通进程
		return p->normal_prio;	//返回常规动态优先级
	return p->prio;	
}

static inline int normal_prio(struct task_struct *p)
{
	int prio;

	if (task_has_dl_policy(p))	//如果是deadline进程
		prio = MAX_DL_PRIO-1;	//#define MAX_DL_PRIO		0  ，优先级变为-1
	else if (task_has_rt_policy(p))//如果是realtime进程
		prio = MAX_RT_PRIO-1 - p->rt_priority;/*#define MAX_USER_RT_PRIO	100  #define MAX_RT_PRIO		MAX_USER_RT_PRIO
												prio = 100-1-实时进程优先级[0,99],若rt_priority为0则表示非实时进程,[1,99]是实时进程*/
	else
		prio = __normal_prio(p);	//返回P的静态优先级
	return prio;
}

static inline int __normal_prio(struct task_struct *p)
{
	return p->static_prio;
}

static inline int rt_prio(int prio)
{
	if (unlikely(prio < MAX_RT_PRIO)) //动态优先级小于100，是实时进程
		return 1;
	return 0;
}

static inline void enqueue_task(struct rq *rq, struct task_struct *p, int flags)
{
	if (!(flags & ENQUEUE_NOCLOCK))
		update_rq_clock(rq);

	if (!(flags & ENQUEUE_RESTORE)) {
		sched_info_queued(rq, p);
		psi_enqueue(p, flags & ENQUEUE_WAKEUP);
	}

	p->sched_class->enqueue_task(rq, p, flags);
}

static inline int task_running(struct rq *rq, struct task_struct *p)
{
#ifdef CONFIG_SMP
	return p->on_cpu;
#else
	return task_current(rq, p);
#endif
}

void resched_curr(struct rq *rq)
{
	struct task_struct *curr = rq->curr;
	int cpu;

	lockdep_assert_held(&rq->lock);

	if (test_tsk_need_resched(curr))	//检查是否已经设置了调度标志
		return;

	cpu = cpu_of(rq);	//根据rq获取CPU

	if (cpu == smp_processor_id()) {	//如果cpu等于当前cpu
		set_tsk_need_resched(curr);		//设置进程需要被调度出去的标志
		set_preempt_need_resched();		//设置cpu抢占
		return;
	}

	if (set_nr_and_not_polling(curr))	//原子balaba
		smp_send_reschedule(cpu);
	else
		trace_sched_wake_idle_without_ipi(cpu);
}

static inline void set_curr_task(struct rq *rq, struct task_struct *curr)//如果调度策略发生变化，调用此函数修改cpu当前的task
{
	curr->sched_class->set_curr_task(rq);
}

struct pid *find_get_pid(pid_t nr)	//获取进程pid
{
	struct pid *pid;

	rcu_read_lock();
	pid = get_pid(find_vpid(nr));
	rcu_read_unlock();

	return pid;
}
EXPORT_SYMBOL_GPL(find_get_pid);

struct task_struct *pid_task(struct pid *pid, enum pid_type type)	//通过pid获取task
{
	struct task_struct *result = NULL;
	if (pid) {
		struct hlist_node *first;
		first = rcu_dereference_check(hlist_first_rcu(&pid->tasks[type]),
					      lockdep_tasklist_lock_is_held());
		if (first)
			result = hlist_entry(first, struct task_struct, pid_links[(type)]);
	}
	return result;
}
EXPORT_SYMBOL(pid_task);

static inline int task_nice(const struct task_struct *p)	//将静态优先级转换为nice值
{
	return PRIO_TO_NICE((p)->static_prio);
}

#define PRIO_TO_NICE(prio)	((prio) - DEFAULT_PRIO)	//动态优先级-120

int task_prio(const struct task_struct *p)
{
	return p->prio - MAX_RT_PRIO;	//动态优先级-100
}
