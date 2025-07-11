from runtime.asyncrt import TaskGroup, _run


trait AsyncCallable:
    async fn __call__(self):
        ...


struct TaskRef[T: AsyncCallable, origin: Origin](AsyncCallable):
    var v: Pointer[T, origin]

    @implicit
    fn __init__(out self, ref [origin]v: T):
        self.v = Pointer(to=v)

    async fn __call__(self):
        await self.v[]()

    fn __add__[
        t: AsyncCallable, o: Origin
    ](self, ref [o]other: t) -> ParTaskPair[T, t, origin, o]:
        return {self.v[], other}

    fn __rshift__[
        t: AsyncCallable, o: Origin
    ](self, ref [o]other: t) -> SerTaskPair[T, t, origin, o]:
        return {self.v[], other}

    fn run(self):
        _run(self())


struct SerTaskPair[
    m1: Bool,
    m2: Bool, //,
    T1: AsyncCallable,
    T2: AsyncCallable,
    o1: Origin[m1],
    o2: Origin[m2],
](AsyncCallable):
    var t1: Pointer[T1, o1]
    var t2: Pointer[T2, o2]

    fn __init__(out self, ref [o1]t1: T1, ref [o2]t2: T2):
        self.t1 = Pointer(to=t1)
        self.t2 = Pointer(to=t2)

    async fn __call__(self):
        await self.t1[]()
        await self.t2[]()

    fn __add__[
        t: AsyncCallable, s: Origin, o: Origin
    ](ref [s]self, ref [o]other: t) -> ParTaskPair[Self, t, s, o]:
        return {self, other}

    fn __rshift__[
        t: AsyncCallable, s: Origin, o: Origin
    ](ref [s]self, ref [o]other: t) -> SerTaskPair[Self, t, s, o]:
        return {self, other}

    fn run(self):
        _run(self())


struct ParTaskPair[
    m1: Bool,
    m2: Bool, //,
    T1: AsyncCallable,
    T2: AsyncCallable,
    o1: Origin[m1],
    o2: Origin[m2],
](AsyncCallable):
    var t1: Pointer[T1, o1]
    var t2: Pointer[T2, o2]

    fn __init__(out self, ref [o1]t1: T1, ref [o2]t2: T2):
        self.t1 = Pointer(to=t1)
        self.t2 = Pointer(to=t2)

    async fn __call__(self):
        tg = TaskGroup()
        tg.create_task(self.t1[]())
        tg.create_task(self.t2[]())
        await tg

    fn __add__[
        t: AsyncCallable, s: Origin, o: Origin
    ](ref [s]self, ref [o]other: t) -> ParTaskPair[Self, t, s, o]:
        return {self, other}

    fn __rshift__[
        t: AsyncCallable, s: Origin, o: Origin
    ](ref [s]self, ref [o]other: t) -> SerTaskPair[Self, t, s, o]:
        return {self, other}

    fn run(self):
        _run(self())
