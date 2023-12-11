---
layout: post
title:  "SQLALchemy vs Django ORM"
date:   2023-12-09 18:19:43 +0000
categories: python sqlalchemy orm django
image: /assets/images/posts/2023-12-09-sqlalchemy-vs-django-orm/sqla_vs_django_upd.png
---

[![SQLALchemy vs Django ORM](/assets/images/posts/2023-12-09-sqlalchemy-vs-django-orm/sqla_vs_django_upd.png "SQLALchemy vs Django ORM")]({{ site.baseurl }}{{ page.url }})

If you are working with Django ORM most of the time and then switching to SQLAlchemy - you may face some unexpected behavior. In this post I'll try to describe the most important differences from my point of view.

All examples for SQLAlchemy will be shown in async code, in context of PostgreSQL. Django version - 4.2, SQLAlchemy version - 2.0.

The full examples can be found here https://github.com/st4lk/sqlalchemy-vs-django-orm, in the article the code will be cutted to be short.

<!--more-->

### "Unit of work" / "Data mapper" and "Active Record" ORM patterns.

In Django we get used to a certain pattern of work with ORM (it is called Active Record). Here are a couple of examples.

#### Different instances for the same DB row

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

In this case assignment `another_m1.value = 'new-value'` didn't modify the `m1.value` since `m1` and `another_m1` - different objects in memory. Although they represent the same row in the database with primary_key = 1.

In SQLAlchemy it is not the same, as long as we are working with "session":

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

Here `m1` and `another_m1` - exactly the same object in memory, although we've made two separate queries with ORM. SQLAlchemy remembered that the row with M1.id == 1 was already acquired and didn't even reach the DB in the second request. Therefore, `another_m1.value = 'new-value'` will change `m1.value`.

#### Creation of two related objects

In Django we must keep the ordering of creation of two related objects:

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

In this example we have to save the parent model first:
```python
parent.save()
```
and only then we can save the `child`.

SQLAlchemy is working a little bit differently, it is accumulating operations that must be sent to DB and actually executing them only when it thinks it is time to. And the ordering of the operations it also defines by itself.

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

Here we've created two instances in ORM's memory, first adding a child to the session and then parent. But SQLAlchemy is smart enough to understand that Parent must be saved first to get the primary key of it and only then we can save the child.

Such an approach to "accumulate" the commands and execute them later is called "Unit of Work". This is not just "lazy" execution that is used in Django for SELECT queries, it is something bigger that includes INSERT/UPDATE operations as well.

### Session

Commands are accumulated inside the "session" in SQLAlchemy.
When a session needs to reach the database for the first time - it acquires a connection from the pool and returns it back to the pool after the commit (or when the session is closed).

We also get used to work with Django in auto-commit mode, when every change is committing in DB automatically. Only when we are wrapping the code with `transaction.atomic()` - the commit will happen at the end of this block. Or if we'll set `ATOMIC_REQUESTS = True` (`False` by default).

In SQLAlchemy we must call `session.commit()` explicitly to actually commit our changes. If a commit wasn't called, all the changes will be rolled back when the session will be closed.

When we are working with an async driver in SQLAlchemy and want to execute two requests concurrently - they must belong to different sessions. Since sessions will be different - there will be two separate connections and therefore two separate transactions. Otherwise, if we'll try to use the same session there will be exception:

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

To execute the requests concurrently the sessions must be different:
```python
async for session in get_session():
    async for another_session in get_session():
        tasks = [
            asyncio.create_task(session.execute(query_one)),
            asyncio.create_task(another_session.execute(query_two)),
        ]
        results = await asyncio.gather(*tasks)
```

#### flush

It may be useful to send (flush) all accumulated commands to the database manually. This doesn't mean the transaction will be committed, this is just sending all the commands to the database. It may be useful in some cases. For example, in some conditions SQLAlchemy may decide, that the statement to create something must be done before deleting something, even if we declared the delete statement first. We can get the exception from the database if instances belong to the same table and have a unique constraint. Here we can use the `session.flush()` right after the delete statement to let the session know that command must be sent to DB right now, before the next creation statement.

### Updating in SQLAlchemy ORM

Because of the fact that SQLAlchemy keeps the one-to-one mapping between rows in the table and ORM instance, sometimes there can be unexpected behavior.

Let's say we wan't to use the "UPSERT" logic of the INSERT in PostgreSQL:

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

In this example we want to apply the following logic for the Storage model: create instance with key='one' and value='new-value' OR update value='new-value' if instance with key='one' already exists. And before doing that we've already acquired the instance for whatever reasons.

If we are falling into the situation when the instance will be created (i.e. it didn't exist before) - everything will be as expected.

But if an instance already exists and we've updated it with such upsert - there can be troubles. SQLAlchemy won't update the instance in memory with a new value, although the upsert logic was executed successfully in the database. And in python code we'll still have old value.

To avoid such case, we can use "populate_existing":

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

Another option - explicitly refresh the instance from the database:
```python
await session.refresh(upserted_instance)
```

There are other functions that can be useful: `expire`, `expunge`. Better to check documentation to understand what they are doing.

#### Regular update

In Django to actually save the changed field value we need to demand it:

```python
my_model = MyModel.objects.get(...)
my_model.value = 'new-value'
my_model.save()
```

I.e. we need to call `.save()` explicitly to actually save it in database.

In SQLAlchemy the '.save()' action is not needed in most of the cases when we are working with session:

```python
cursor = await session.execute(sa.Select(MyModel).where(...))
my_model = cursor.scalar_one()
my_model.value = 'new-value'

await session.commit()
```
Since in SQLAlchemy model instance is a one-to-one mapping with DB row, the code:
```python
my_model.value = 'new-value'
```
is already a signal for the ORM to update the field in DB. And when it will be time, SQLAlchemy will generate an `UPDATE ...` request by itself, no need to call for it explicitly.

### Analog of select_related, prefetch_related in SQLAlchemy

Django has useful queryset methods that can save database queries (using JOIN or IN query): `select_related`, `prefetch_related`. In SQLAlchemy we can JOIN explicitly, but usually it is more convenient to use "dot" notation to follow the relations instead of getting two separate joined instances.

Example:

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

As we can see, relations must be described explicitly with the `relationship` function. In Django it is happening automatically. This is not a required step in SQLAlchemy, but it provides syntax sugar that really makes the work easier.

#### Analog of select_related: joinedload

To get all Childs with their Parents with one query (it will be JOIN):

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

#### Analog of prefetch_related: selectinload

To get Parents along with all their children with two queries (second one will be "IN" query):
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

#### Methods chaining

`selectinload`, `joinedload` can be chained.

Example:
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

In this case there is no real need in joining the parent back to the child since the parent is already there. Just to show how we can make the chain of methods.

### Primary Key

Django creates a primary key column automatically for us (if we didn't specify it explicitly).

In SQLAlchemy we have to define it manually. Analog of primary key in SQLAlchemy that Django adds automatically:

```python
class MyModel(Base):
    __tablename__ = 'pk_identity'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
```

No need to add `index=True` or `unique=True`, it will create an additional useless index in the database that will use memory. The `primary_key` is enough, in the database such columns will already be unique, indexed and not null.

### Foreign Key

By default Django adds indexes for all ForeignKey columns. In SQLAlchemy - this is not true, it must be set explicitly.

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

If we'll check the tables created by ORMs - we'll see that Django has defined the index:
```
Indexes:
    "fk_child_pkey" PRIMARY KEY, btree (id)
    "fk_child_parent_id_d610db4a" btree (parent_id)
```
and SQLAlchemy (alembic to be specific) didn't add `btree (parent_id)` index (if we didn't specify `index=True`).

FK indexes may impact such queries:
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

To JOIN the Parent with Child database has to search the Child by the parent_id column. If it is not indexes - Seq Scan will be used, which may be slow for big tables.

To fix it, add the index:
```python
class Child(Base):
    __tablename__ = 'child'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    parent_id = sa.Column(sa.Integer, sa.ForeignKey(Parent.id), index=True)
```

### Nullable

Django makes the column NOT NULL by default:
```python
class NullableFieldsModel(models.Model):
    value = models.CharField(max_length=50)
```

Here the default will be `null=False`.

In SQLAlchemy it is vice versa, by default `nullable=True`:

```python
class NullableFieldsModel(Base):
    __tablename__ = 'nullable_model'

    id = sa.Column(sa.Integer, sa.Identity(), primary_key=True)
    value = sa.Column(sa.String(50))  # nullable
```
(if we are not using syntax with type annotation).

### Preloading models

Sometimes, when we define `relationship(...)` for SQLAlchemy models in our project that has many `models.py` (or whatever) modules, there can be such an error:

```python
sqlalchemy.exc.InvalidRequestError: When initializing mapper Mapper[LoadedParent(relations_loaded_parent)], expression 'UnloadedChild' failed to locate a name ('UnloadedChild'). If this is a class name, consider adding this relationship() to the <class 'relations_not_loaded.models.LoadedParent'> class after both dependent classes have been defined.
```

Usually it means that the relationship points to a model that is not loaded yet. Therefore SQLAlchemy doesn't know about it and throws such an exception.
For reliability we can iterate over all our modules with models and just import it during the start of our project. After that such error must be gone.

### TaskGroup vs gather

When we are using `gather`:

```python
tasks = [
    asyncio.create_task(session.execute(query_one)),
    asyncio.create_task(smth_that_raise_exception()),
]
results = await asyncio.gather(*tasks)
```
and one of the task throws an exception - it propagates to our code immediately. Other tasks are not cancelled.

Because of that there can be strange errors with SQLAlchemy session.

To fix it:
- either use `asyncio.gather(*tasks, return_exceptions=True)`

    in that case exceptions will be returned as normal results, we must check them manually

- or use `asyncio.TaskGroup()` (available in python 3.11+)

    ```python
    async with asyncio.TaskGroup() as tg:
        task1 = tg.create_task(session.execute(query_one))
        task2 = tg.create_task(smth_that_raise_exception())
    ```

More details about this problem can be found here:
https://github.com/sqlalchemy/sqlalchemy/discussions/9312#discussioncomment-6419638
