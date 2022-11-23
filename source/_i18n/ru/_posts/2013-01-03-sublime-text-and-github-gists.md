---
layout: post
title:  "Sublime text и github gists"
date:   2013-01-03 18:19:43 +0000
categories: sublime
redirect_from:
  - /2013/sublime-text-and-github-gists/
---

[![Sublime text и github gists](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/logo_full.jpeg "Sublime text и github gists")]({{ site.baseurl }}{{ page.url }})

В [Sublime text](http://www.sublimetext.com/) есть огромное количество полезных инструментов, помогающих быстро писать код. Пока я изучил лишь небольшую их часть, в том числе пытаюсь привыкнуть к Vintage mode (управление курсором в стиле vim). Но сейчас хочу рассказать о другом - об интеграции [github gists](https://gist.github.com/) с sublime text. Если вы не знаете, github gists позволяет сохранять скрипты, снипеты в виде отдельного файла, чтобы не создавать для этого целый репозиторий. При этом поддерживаются многие функции репозитория - версии, возможность форка.

<!--more-->

### Что мы получим в итоге

Сохраняем снипет прямо из sublime, даем ему описание в виде ключевых слов, затем опять-таки из sublime ищем наш снипет по ключевым словам и видим его в редакторе. Все снипеты сохраняются на github, т.е. они доступны и с другого компьютера.

Не стоит забывать, что в самом sublime есть свой настраиваемый функционал снипетов. Однако он больше подходит для маленьких авто-заполнений, например при наборе def для питон кода вставлять шаблон для написания функции:

```python
def function():
    pass
```

Снипеты в github gist подходят для чего-то большего - какая-либо готовая функция, которая делает конкретную задачу.

### Настроим этот функционал в нашем редакторе

#### Установим плагин для работы с github gist

Проще всего это сделать с помощью пакетного менеджера sublime. [Здесь](http://wbond.net/sublime_packages/package_control/installation) есть инструкция для его установки. В sublime нажимаем `ctrl + shift + p`, вводим `install`, и далее `gist`:

![Sublime install package](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/1_package_control_install.jpeg "Sublime install package")

![Sublime install gist package](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/2_package_control_gist.jpeg "Sublime install gist package")

#### Теперь дадим плагину доступ к нашему github аккаунту

Нажимаем Preferences->Package settigns->Gist->Settings User.

![Gist sublime Preferences](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/3_gist_settings_menu.jpeg "Gist sublime Preferences")

Можно либо указать логин+пароль, либо токен. Если нужных настроек в Settings User нет, то их можно скопировать из Settings Default. Только default settings лучше не менять. Чтобы получить токен, нужно в командной строке выполнить такую команду (должен быть установлен [curl](http://curl.haxx.se/)):

```bash
curl -v -u USERNAME -X POST https://api.github.com/authorizations --data "{\"scopes\":[\"gist\"]}"
```

Где USERNAME - ваш логин на github

![Gist sublime settings](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/4_gist_auth.jpeg "Gist sublime settings")

#### Создадим gist

Пишем код нашего снипета в новой вкладке sublime. Я написал код для получения содержимого csv файла в виде списка списков. Нажимаем `ctrl + shift + p`, вводим `gist create public` и enter. Здесь работает fuzzy поиск, так что я набираю просто `public`.

![Gist sublime create](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/5_gist_create_public.jpeg "Gist sublime create")

Даем нашему снипету описание. Важно включить значащие слова, т.к. по ним потом будет идти поиск. Я напишу так "Python: Get csv lines".

![Gist sublime description](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/6_gist_set_description.jpeg "Gist sublime description")

Будет еще запрос на название файла, можно просто нажать enter.

#### Найдем только что созданный снипет

Вызываем строку ввода команд `ctrl + shift + p` и пишем `gist open`.

![Gist sublime open](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/7_gist_open.jpeg "Gist sublime open")

Далее пишем ключевые слова "python csv"

![Gist sublime find](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/8_gist_find_by_descr.jpeg "Gist sublime find")

И видим код снипета

![Gist sublime opened](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/9_gist_opened.jpeg "Gist sublime opened")


Этот снипет так же создался на github: [https://gist.github.com/3931305](https://gist.github.com/3931305).

#### Ссылки

- Редактор кода [sublime text](http://www.sublimetext.com/)
- [Репозиторий](https://github.com/condemil/Gist) плагина Gist
- [Видео](https://tutsplus.com/lesson/sexy-code-snippet-management-with-gists/) про sublime и github gist на [tutsplus.com](http://tutsplus.com/) (на английском)
- [Видео курс](https://tutsplus.com/course/improve-workflow-in-sublime-text-2/) по sublime text на [tutsplus.com](http://tutsplus.com/) (на английском)
