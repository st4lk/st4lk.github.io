---
layout: post
title:  "SQLALchemy vs Django ORM"
date:   2023-12-09 18:19:43 +0000
categories: python sqlalchemy orm django
image: /assets/images/posts/2023-12-09-sqlalchemy-vs-django-orm/sqla_vs_django_upd.png
---

[![SQLALchemy vs Django ORM](/assets/images/posts/2023-12-09-sqlalchemy-vs-django-orm/sqla_vs_django_upd.png "SQLALchemy vs Django ORM")]({{ site.baseurl }}{{ page.url }})

Если большую часть времени вы работаете с Django ORM и вам надо перейти на SQLALchemy - то вы встретите ряд концептуальных отличий. В этом посте опишу часть из них, на мой взгляд заметных больше всего.

Все примеры для SQLAlchemy буду приводить в асинхронном коде, в контексте PostgreSQL. Версия Django - 4.2, SQLALchemy - 2.0.

Полные примеры можно найти тут https://github.com/st4lk/sqlalchemy-vs-django-orm, в тексте для краткости код приведен не полностью.

<!--more-->

### Паттерны "Unit of work" / "Data mapper" и "Active Record"

В Django мы привыкли к определенному паттерну работы с ORM (называется Active Record). Вот несколько примеров.

#### Разные объекты для одной строки в БД

```python
class M1(models.Model):
    value = models.CharField(max_length=50)

M1.objects.create(pk=1, value='old-value')
m1 = M1.objects.get(pk=1)
another_m1 = M1.objects.get(pk=1)

another_m1.value = 'new-value'

>>> print(m1.value)
'old-value'
>>> print(another_m1.value)
'new-value'
```

В этом случае присваивание `another_m1.value = 'new-value'` никак не повлияло на `m1.value`, ведь `m1` и `another_m1` - разные объекты в памяти, хоть и представляют одну и ту же строку в БД с primary_key = 1.

В SQLAlchemy же это не так, т.к. там мы обычно работаем в рамках "сессии":

```python
import sqlalchemy as sa

class M1(Base):
    __tablename__ = 'm1'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    value = sa.Column(sa.String(50))

# acquire session somehow

# create M1 with value = 'old-value'
statement = sa.Select(M1).where(M1.id == 1)
cursor = await session.execute(statement)
m1 = cursor.scalar_one()

same_statement = sa.Select(M1).where(M1.id == 1)
cursor = await session.execute(same_statement)
another_m1 = cursor.scalar_one()

another_m1.value = 'new-value'

>>> print(m1 is another_m1)
True
>>> print(m1.value)
'new-value'
>>> print(another_m1.value)
'new-value'
```

Здесь `m1` и `another_m1` - один и тот же объект в памяти, хоть мы и сделали два запроса с помощью ORM. SQLAlchemy запомнила, что запись с M1.id == 1 уже есть в памяти, и во втором запросе даже не обратилась к БД, а взяла закешированный объект. Соответственно, `another_m1.value = 'new-value'` изменяет и `m1.value`.

#### Создание родительской и дочерней записи.

В Django при создании двух связанных объектов нужно сохранять очередность:

```python
class Parent(models.Model):
    pass


class Child(models.Model):
    parent = models.ForeignKey(Parent, on_delete=models.CASCADE)


parent = Parent()
child = Child(parent=parent)

>>> child.save()
ValueError: save() prohibited to prevent data loss due to unsaved related object 'parent'.
```

В данном примере надо вначале явно сохранить родительскую модель:
```python
parent.save()
```
и только после этого можно сохранять `child`.

SQLAlchemy действует немного по-другому, она накапливает операции в памяти и отправляет их в БД только когда это действительно нужно. И порядок их отправления тоже определяет сама.

```python
import sqlalchemy as sa

class Parent(Base):
    __tablename__ = 'parent'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)

    children = sa.orm.relationship('Child', back_populates='parent')


class Child(Base):
    __tablename__ = 'child'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    parent_id = sa.Column(sa.Integer, sa.ForeignKey(Parent.id))

    parent = sa.orm.relationship(Parent, back_populates='children')


parent = Parent()
child = Child(parent=parent)
session.add(child)
session.add(parent)
await session.commit()
```

Тут мы создали два инстанса в памяти, в сессию вначале добавили child, потом parent. Но SQLAlchemy смогла понять, что вначале нужно сохранить родителя, потом потомка, чтобы присвоить верное значение в parent_id. И все успешно сохранилось.

Такой подход "накапливания" запросов и выполнения их позднее называется "Unit of Work". Это не просто "ленивое" выполнение, которое используется в django для SELECT запросов, это нечто большее, используемое и для INSERT/UPDATE запросов.

### Сессия

Действия с БД накапливаются в рамках "сессии" в SQLAlchemy.
При первом обращении к БД сессия запрашивает коннекшн из пула и возвращает его обратно в пул после коммита транзакции (или закрытии сессии).

Мы так же привыкли, что по умолчанию Django работает в авто-коммит режиме, когда каждое изменение в БД автоматически коммититься. Только если мы оборачиваем в `transaction.atomic()` - тогда коммит произойдет в конце блока atomic. Или если выставим `ATOMIC_REQUESTS = True` (по умолчанию False).

А в SQLAlchemy нам нужно явно вызывать `session.commit()` чтобы наши изменения закоммитились. Если этого не сделать и закрыть сессию - все изменения, сделанные в сессии, откатятся.

Когда работаем с асинхронным драйвером в SQLAlchemy и хотим выполнить два запроса конкурентно - они должны выполняться в разных сессиях. Т.к. сессии разные - будут разные коннекты к БД и соответственно разные транзакции. Если же это будет одна и та же сессия (а значит один коннект и одна и та же транзакция) - то SQLAlchemy выкинет ошибку:

```python
query_one = sa.Select(M1).where(M1.id == 1)
query_two = sa.Select(M1).where(M1.id == 2)

async for session in get_session():
    tasks = [
        asyncio.create_task(session.execute(query_one)),
        asyncio.create_task(session.execute(query_two)),
    ]
    results = await asyncio.gather(*tasks)

...

sqlalchemy.exc.InvalidRequestError: This session is provisioning a new connection; concurrent operations are not permitted (Background on this error at: https://sqlalche.me/e/20/isce)
```

Чтобы выполнить эти запросы конкурентно, сессии должны быть разные, например:
```python
async for session in get_session():
    async for another_db_session in get_session():
        tasks = [
            asyncio.create_task(session.execute(query_one)),
            asyncio.create_task(another_db_session.execute(query_two)),
        ]
        results = await asyncio.gather(*tasks)
```

#### flush

В некоторых случаях может быть полезно принудительно отправить накопленные на текущий момент команды в БД.
Это не коммит транзакции, а просто отправка команд в БД. Это пригодится, например, если вы удаляете инстанс, а потом создаете новый с тем же значением уникального поля, что было у удаленной строки. При определенных обстоятельствах сессия в алхимии может решить, что вначале следует отправить команду на создание, а только потом - на удаление, несмотря на то что в коде команда на удаление объявлена раньше. Тогда мы получим ошибку данных от БД, т.к. мы попытаемся сохранить не уникальное значение. Тут может помочь flush - после запроса на удаление вызываем `session.flush()`, тогда удаление будет точно перед созданием.


### Обновление инстанса модели в SQLAlchemy ORM

Из-за того, что алхимия держит записи с одним и тем же primary key в одном и том же объекте (в одном адресе в памяти), иногда может быть неожиданное поведение.

Например, если используется Postgres, то для insert можно использовать логику upsert из БД, т.е. обновить или создать за один запрос:

```python
from sqlalchemy.dialects.postgresql import insert as upsert

class Storage(Base):
    __tablename__ = 'populate_existing_storage'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    key = sa.Column(sa.String(50), nullable=False, unique=True)
    value = sa.Column(sa.String(50), nullable=False)

cursor = await session.execute(sa.Select(Storage).where(Storage.key == 'one'))
# already fetched instance
instance = cursor.scalar_one_or_none()

>>> print(instance.value) if instance else None
'old-value'

upsert_statement = upsert(Storage).values(
    key='one', value='new-value',
).on_conflict_do_update(
    index_elements=[Storage.key],
    set_={'value': value},
).returning(Storage)

cursor = await session.execute(upsert_statement)
upserted_instance = cursor.scalar_one()
await session.commit()

new_cursor = await session.execute(sa.Select(Storage).where(Storage.key == 'one'))
fresh_instance = new_cursor.scalar_one()

>>> print(fresh_instance.value)
'old-value'
```

В этом примере мы хотим применить логику для модели Storage: создай объект с key='one' и value='new-value' ИЛИ обнови на value='new-value', если объект с key='one' уже существует. Причем до upsert мы уже запросили его из БД по каким-то причинам.

Если мы попали в случай, когда объект создан - все будет как мы и ожидаем, после коммита транзакции значение будет value == 'new-value'.

А вот если получилось, чтоб объект уже был и мы его обновили в БД с помощью upsert - алхимия будет считать, что объект все тот же, что есть у нее в памяти. И поэтому забирать его из БД не нужно.
И казалось бы, ведь мы честно запрашиваем его из БД с помощью Select. Но алхимия неумолимо берет его из своего кеша и показывает то значение, которое было до обновления.

В этом случае поможет опция populate_existing:

```python
upsert_statement = upsert(Storage).values(
    key=key, value=value,
).on_conflict_do_update(
    index_elements=[Storage.key],
    set_={'value': value},
).returning(Storage)

statement = sa.Select(
    Storage,
).from_statement(
    upsert_statement,
).execution_options(populate_existing=True)

cursor = await session.execute(statement)
upserted_instance = cursor.scalar_one()
await session.commit()

new_cursor = await session.execute(sa.Select(Storage).where(Storage.key == 'one'))
fresh_instance = new_cursor.scalar_one()

>>> print(fresh_instance.value)
'new-value'
```

Другой вариант - принудительно обновить объект из БД:
```python
await session.refresh(upserted_instance)
```

Есть еще функции сессии которые также могут быть полезны: `expire`, `expunge`. Лучше почитать про них в документации.

#### Обычное обновление

Для того, чтобы просто сохранить данные в Django, нужно явно сказать об этом:

```python
my_model = MyModel.objects.get(...)
my_model.value = 'new-value'
my_model.save()
```

Т.е. мы должны вызвать `.save()` чтобы данные попали в БД.

В SQLAlchemy это делать необязательно в большинстве случаев:

```python
cursor = await session.execute(sa.Select(MyModel).where(...))
my_model = cursor.scalar_one()
my_model.value = 'new-value'

await session.commit()
```

Т.к. инстанс модели - это прямое отображение строки в БД, код:

```python
my_model.value = 'new-value'
```
уже говорит ORM'у, что это поле должно обновиться. И когда придет время, ORM сама отправить `UPDATE ...` запрос в БД, явного `save()` или `update()` не требуется.

### Аналоги select_related, prefetch_related в SQLAlchemy

В Django есть полезные методы, которые подгружают связанные сущности (либо JOIN, либо IN запрос): `select_related`, `prefetch_related`. В SQLAlchemy мы можем явно JOIN'ить то, что на нужно, но часто бывает удобнее привязывать связанные объекты к родительскому и обращаться к ним через "точку" из родительского объекта.

Пример:

```python
import sqlalchemy as sa


class Parent(Base):
    __tablename__ = 'parent'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    value = sa.Column(sa.String(50))

    children = sa.orm.relationship('Child', back_populates='parent')


class Child(Base):
    __tablename__ = 'child'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    parent_id = sa.Column(sa.Integer, sa.ForeignKey(Parent.id))
    value = sa.Column(sa.String(50))

    parent = sa.orm.relationship(Parent, back_populates='children')
```

Как видим, связи для ORM нужно указывать явно, с помощью relationship, в отличие от Django, где это происходит автоматически. Это необязательный шаг в SQLAlchemy, чтобы можно было использовать более удобный синтаксис.


#### Аналог select_related: joinedload

Получить все Child'ы с их Parent'ами за один запрос (будет JOIN) можно так:
```python
query = sa.Select(
    Child,
).options(
    sa.orm.joinedload(Child.parent),
)
cursor = await session.execute(query)
children = cursor.scalars().all()

for child in children:
    print('child.value:', child.value)
    print('child.parent.value:', child.parent.value)
```

#### Аналог prefetch_related: selectinload

Получить все Parent'ы со всеми их Child'ами за два запроса (IN) можно так:
```python
query = sa.Select(
    Parent,
).options(
    sa.orm.selectinload(Parent.children),
)
cursor = await session.execute(query)
parents = cursor.scalars().all()

for parent in parents:
    print('parent.value:', parent.value)
    for child in parent.children:
        print("parent's child.value:", child.value)
```

#### Цепочка методов

`selectinload`, `joinedload` можно объединять в цепочки.

Например:
```python
query = sa.Select(
    Parent,
).options(
    sa.orm.selectinload(Parent.children).joinedload(Child.parent),
)
cursor = await session.execute(query)
parents = cursor.scalars().all()

for parent in parents:
    print('parent.value:', parent.value)
    for child in parent.children:
        print("parent's child.value:", child.value)
        print("child.parent.value:", child.parent.value)
```

В данном случае особого смысла опять JOIN'ить parent'а к child'у нет, ведь у нас уже есть parent.
Но думаю смысл ясен.

### Primary Key

Django создает primary key автоматически (если мы явно его не указали при создании модели).
В Алхимии его надо объявлять вручную. Аналог primary key в алхимии, который создает Django:

```python
class MyModel(Base):
    __tablename__ = 'pk_identity'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
```

Не надо добавлять `index=True` или `unique=True`, это создаст дополнительный индекс, который будет занимать память.
Со свойством `primary_key=True` поле уже будет уникальным, проиндексированным, и не нулевым.

### Foreign Key

Django по умолчанию ко всем полям ForeignKey добавляет индекс. В SQLALchemy - нет, это нужно делать явно.

Пример.

Django:
```python
class Parent(models.Model):
    pass


class Child(models.Model):
    parent = models.ForeignKey(Parent, on_delete=models.CASCADE)
```

SQLAlchemy:
```python
class Parent(Base):
    __tablename__ = 'parent'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)


class Child(Base):
    __tablename__ = 'child'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    parent_id = sa.Column(sa.Integer, sa.ForeignKey(Parent.id))
```

Если посмотрим на таблички, созданные ORM'ами, то увидим, что в случае Django индексы есть:
```
Indexes:
    "fk_child_pkey" PRIMARY KEY, btree (id)
    "fk_child_parent_id_d610db4a" btree (parent_id)
```
а в SQLAlchemy (alembic если быть точным) индекса `btree (parent_id)` не будет (если явно не указать `index=True`).

Индексы на FK влияют на такие запросы:
```python
query = sa.Select(
    Child,
).join(
    Parent,
    Parent.id == Child.right_id,
).where(
    Parent.id == 95435,  # or other filters by Parent's
)
```

Чтобы сджонить Parent к Child'у базе данные нужно делать поиск по колонке Child.parent_id.
Если индекса на ней нет - то будет Seq Scan.
Соответственно для FK с индексом будет выглядеть так:

```python
class Child(Base):
    __tablename__ = 'child'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    parent_id = sa.Column(sa.Integer, sa.ForeignKey(Parent.id), index=True)
```

### Nullable

В Django по умолчанию поле - обязательное, т.е. NOT NULL:
```python
class NullableFieldsModel(models.Model):
    value = models.CharField(max_length=50)
```

Здесь для поля value будет `null=False`.

В Алхимии наоборот, если явно не указать nullable - то поле будет не обязательным, т.е. `nullable=True`:

```python
class NullableFieldsModel(Base):
    __tablename__ = 'nullable_model'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    value = sa.Column(sa.String(50))
```
если используется синтаксис без аннотации типов.

### Preloading models

Иногда, когда объявляем `relationship(...)` в моделях SQLAlchemy, может появиться такая ошибка:

```python
sqlalchemy.exc.InvalidRequestError: When initializing mapper Mapper[LoadedParent(relations_loaded_parent)], expression 'UnloadedChild' failed to locate a name ('UnloadedChild'). If this is a class name, consider adding this relationship() to the <class 'relations_not_loaded.models.LoadedParent'> class after both dependent classes have been defined.
```

Обычно это значит, что в relationship указана модель, которая не была еще импортирована и соответственно Алхимия про нее пока ничего не знает.
Для надежности, можно при старте проекта пройтись по всем модулям, где объявлены модели, и просто их импортнуть.
Тогда такой ошибки быть не должно.

### TaskGroup vs gather

Когда мы используем `gather`:

```python
tasks = [
    asyncio.create_task(session.execute(query_one)),
    asyncio.create_task(smth_that_raise_exception()),
]
results = await asyncio.gather(*tasks)
```
и одна из задача выкидывает исключение, то это исключение сразу пробрасывается к нам, остальные таски не отменяются.

Из-за этого могут быть неочевидные ошибки с сессией Алхимии.

Решение проблемы:
- либо использовать `asyncio.gather(*tasks, return_exceptions=True)`

    тогда эксепшены будут возвращаться как обычные результат, надо будет самим их проверить

- либо использовать `asyncio.TaskGroup()` (доступно в python 3.11+)

    ```python
    async with asyncio.TaskGroup() as tg:
        task1 = tg.create_task(session.execute(query_one))
        task2 = tg.create_task(smth_that_raise_exception())
    ```

Больше деталей об этой проблеме можно найти тут:
https://github.com/sqlalchemy/sqlalchemy/discussions/9312#discussioncomment-6419638
