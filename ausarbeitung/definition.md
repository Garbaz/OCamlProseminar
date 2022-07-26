# Data-races & Event Reordering

## Definition

### Program & Threads

A _concurrent program_ $P$ consists of a set of _threads_ $T = \left\{ t_1, ..., t_n \right\}$.

### Action & Event

An _event_ $e = (i, a)$ is any _action_ $a$ performed by a thread $t_i$ which potentially influences or is influenced by the execution of other threads. An action can be:

- $read(x)$ : Read from variable $x$
- $write(x)$ : Write to variable $x$
- $lock(l)$ : Acquire lock $l$
- $unlock(l)$ : Release lock $l$
- $fork(j)$ : Create child thread $t_j$
- $join(j)$ : Await child thread $t_j$ to terminate

Hereby is $x$ the identifier of a _global variable_, $l$ the identifier of a _lock_ and $j$ is the index of a child thread $t_j$.

### Trace of a program

The _trace_ $\sigma = \left\{ e_1 , e_2 , ..., e_m \right\}$ of a program $P$ is the temporally ordered sequence of events of the threads $T$ in $P$ for a potential execution of $P$.

### Last-Write of a Read Action

For a read event $e = (i, read(x))$, we define the _last-write_ of $e$ as the last event $e' = (j, write(x))$ that wrote to $x$ before $e$ by any thread. We write $lastwrite(a) = a'$.

### Reordering & Happens-Before Relation

The relation _happens-before_ between any two events $e=(i, a)$ and $e'=(j, a')$, written $e \prec e'$, is defined if any of the following conditions are met:

- $i = j$ and $a$ happens before $a'$ in $t_i$
- $a = fork(j)$
- $a' = join(i)$
- $i \neq j$ and $a = unlock(l)$ and $a' = lock(l)$

A _valid reordering_ $r : \left\{1,...,m\right\} \rarr \left\{1,...,m\right\}$ of the trace $\sigma = \left\{e_1, ..., e_m\right\}$ of a program $P$ is a bijective function that preserves the _happens-before_ relation between all events:

$$
\forall k \in \left\{1,...,m\right\} \forall l \in \left\{1,...,m\right\}: e_k \prec e_l \rArr e_{r(k)} \prec e_{r(l)}
$$

### Data Race

A _data race_ exists for a read event $e_k = (i, read(x))$ if there is a valid reordering $r$ of the program's trace $\sigma = \left\{e_1, ..., e_m\right\}$ that changes the last-read of $a$:

$$
lastread(e_k) \neq lastread(e_{r(k)})
$$

## Sources

1. <https://link.springer.com/content/pdf/10.1007/978-3-642-14295-6_39.pdf>
2. <https://dl.acm.org/doi/pdf/10.1145/359545.359563>
