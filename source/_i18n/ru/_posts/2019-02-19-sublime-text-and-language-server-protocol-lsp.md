---
layout: post
title:  "Sublime Text и Language Server Protocol"
date:   2019-02-19 18:19:43 +0000
categories: python sublime lsp
redirect_from:
  - /2019/sublime-text-and-language-server-protocol-lsp/
image: https://i.ibb.co/4K4zp06/sublime-256-lsp-light.png
---

[![Sublime Text и Language Server Protocol (LSP)](https://i.ibb.co/4K4zp06/sublime-256-lsp-light.png
 "Sublime Text и Language Server Protocol (LSP)")]({{ site.baseurl }}{{ page.url }})

Language Server Protocol (LSP)
---

Language Server Protocol (LSP) - протокол для общения между IDE и языковым сервером. Сервер предоставляет такие функции, как автокомплит, переход к функции (goto) и прочее. Т.е. когда IDE нужно показать автокомплит на языке, скажем, python - происходит запрос к специальному серверу. В ответе возвращаются необходимые данные, которые IDE уже может отобразить. Радует то, что это инициатива крупной компании - Microsoft.

<!--more-->

Но в чем же смысл, ведь в большинстве IDE это итак уже работает?

Смысл в унификации таких возможностей, в простоте разработки самих IDE. Получается, что сервер - один, а сред разработки - много. И все они могут общаться с одним сервером, им не нужно реализоваывать стандартные функции, специфичные для каждого конкретного языка. Все, что нужно сделать - это реализовать общение с сервером согласно LSP.

С точки зрения пользователей самих IDE тоже есть плюс. К примеру, если на сервере добавят что-то новое, то такие обновления вы получите быстрее. Не важно, каким именно IDE или редактором кода вы пользуетесь, теперь это не зависит от этого. Главное, что ваш редактор должен поддерживать - это протокол общения с сервером. Можем считать, что он будет стабильным в ближайшее время. Тем более его поддерживает такой гигант, как Microsoft.

Некоторые ссылки:

- Официальная страница LSP: [https://microsoft.github.io/language-server-protocol/](https://microsoft.github.io/language-server-protocol/)
- Список реализаций серверов: [https://microsoft.github.io/language-server-protocol/implementors/servers/](https://microsoft.github.io/language-server-protocol/implementors/servers/)
- Страница, поддерживаемая сообществом: [https://langserver.org/](https://langserver.org/)

Python Server
-------------
Давайте попробуем подружить IDE (на примере Sublime Text) с python language server.

Первое, что нам понадобиться - это сам сервер, который будет отвечать на запросы LSP.
На момент написания статьи, самый поддерживаемый сервер, написанный на python'e, этот: [https://github.com/palantir/python-language-server](https://github.com/palantir/python-language-server).

Есть так же сервер от Microsoft: [https://github.com/Microsoft/python-language-server/](https://github.com/Microsoft/python-language-server/).
И даже есть [краткая инструкция](https://github.com/Microsoft/python-language-server/blob/master/Using_in_sublime_text.md) по настройке с Sublime Text. Для запуска этого сервера понадобится [dotnet](https://dotnet.microsoft.com/download/dotnet-core/2.1).
Пробовал ставить, однако в полной мере он не выдавал нужный мне функционал. Возможно, я что-то недонастроил. К тому же я редко сталкиваюсь с C# в работе, поэтому понять внутренности для меня трудно, а иногда это бывает полезно.

Но вернемся к серверу на питоне.
Схема в голове была такая:

1. У нас есть отдельный virtualenv, созданный исключительно для установки сервера LSP
2. В virtualenv нашего проекта никаких LSP серверов нет
3. Наш IDE будет общаться с сервером, передавая параметры virtualenv'а нашего проекта.

Таким образом, раз установив сервер, мы можем использовать его для разных проектов.
Но на момент описания этой статьи сделать это было не просто. По крайней мере четкой документации, как это сделять, я не нашел. В документации к этому серверу как-то неявно предполагается, что он должен быть установлен в той же среде, что и ваш проект. В том же virtualenv. Но мне кажется это не совсем удобно.
Поэтому пришлось создать [PR](https://github.com/palantir/python-language-server/pull/401).

Так же, этот LSP не хотел брать настройки линтера из директории проекта. Например, в корне проекта у меня лежит setup.cfg с такими настройками:

    ignore = D202,D205,D211
    max-line-length = 99

Чтобы сервер мог подхватывать их, понадобился еще один [PR](https://github.com/palantir/python-language-server/pull/413).
Который в свою очередь преобразовался в [этот](https://github.com/palantir/python-language-server/pull/418).

Были и другие проблемы, тоже приходилось погружаться в код и создавать PR'ы.
Надеюсь, их скоро примут и включат в релиз. А пока, создал релиз в своем [форке](https://github.com/st4lk/python-language-server/releases/tag/0.22.0a1), где найденные мной ошибки исправлены.

По порядку:

- Создаем virtualenv специально для сервера LSP. Лучше python3.6+.
- Устанавливаем туда наш сервер (этот релиз уже содержит упомянутые выше исправления):

        pip install https://github.com/st4lk/python-language-server/archive/0.22.0a1.zip

Если хотите создать requirements.txt - то туда можно вставлять ссылку на zip файл без каких-либо префиксов/суффиксов.

Хотя возможно, что на момент чтения статьи это уже все исправлено в официальной версии `> 0.22`. Не поленитесь проверить основной репозиторий.

Sublime Text
------------
Теперь перейдем к настройке IDE. В этом посте речь пойдет о Sublime Text. Мне нравится этот редактор кода. Хоть это и не полноценный IDE, но я люблю его скорость, его vintage режим, мультикурсоры и много других маленьких фишек.

Итак, как же подружить Sublime с LSP?
В первую очередь, нам понадобится плагин для общения с LSP сервером: [https://github.com/tomv564/LSP](https://github.com/tomv564/LSP).

Теперь самое важное - правильно его настроить.
Идем в настройки нашего плагина (на MacOS это _Sublime Text -> Preferences -> Package Settings -> LSP -> Settings_).
В пользовательских настройках вводим примерно следующее:

    {
      "clients": {
        "pyls":
        {
          "enabled": true,
          "command": [
            "~/.virtualenvs/python-language-server/bin/pyls"
          ],
          "settings": {
            "pyls": {
              "configurationSources": ["flake8"],
              "plugins": {
                "jedi_definition": {
                  "follow_imports": true
                }
              }
            }
          },
          "scopes": ["source.python"],
          "syntaxes": [
            "Packages/Python/Python.sublime-syntax",
            "Packages/Djaneiro/Syntaxes/Python Django.tmLanguage"
          ],
          "languageId": "python"
        }
      }
    }

Давайте пройдемся по основным настройкам.

**"command"** - путь к исполняемому файлу нашего pyls сервера. Как видно, у меня он установлен в virtualenv `~/.virtualenvs/python-language-server/` (я использую [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/en/latest/)). Это не виртуальное окружение вашего проекта! Здесь установлен только pyls.

**"settings" : "pyls" : "configurationSources"**. Тут можно указать, где брать настройки линтера для проекта. По умолчанию это "pycodestyle", однако я чаще использую flake8. Т.о. pyls будет искать настройки в таких файлах:

    '.flake8', 'setup.cfg' (секция [flake8]), 'tox.ini'

Настройка **"follow_imports": true**. Без нее, goto будет показывать лишь место импорта, а не саму реализацию. Мне кажется такое поведение не приносит особой пользы, обычно я хочу посмотреть именно на реализацию функции или класса, а не то, откуда он был импорирован. Кстати, чтобы это было воспринято сервером, потребовался небольшой патч: [https://github.com/palantir/python-language-server/pull/404/](https://github.com/palantir/python-language-server/pull/404/).

Еще важный момент: настройка **"syntaxes"**. Если вы используйте плагин [Djaneiro](https://github.com/squ1b3r/Djaneiro) (добавляет ряд фишек для работы с Django проектом), то sublime будет считать синтаксис python файлов - Djaneiro, а не дефолтный Python. Поэтому нужно указать его для нашего LSP сервера, иначе Sublime просто не будет его запускать.

Тут мы объявили глобальные настройки, которые будут применяться ко всем файлам с синтаксисом python.
А как объявить настройки, специфичные для каждого конкретного проекта?

Как ни странно, их можно объявить в настройках проекта :). Идем _Project -> Edit project_ и добавляем следующее:

    {
      "folders":
      [
          {
              "path": "/Path/to/my/project"
          },
      ],
      "settings":
      {
        "LSP":
        {
          "pyls":
          {
            "env":
            {
              "VIRTUAL_ENV": "/path/to/my/project/virtualenv/"
            }
          }
        }
      }
    }

С помощью **"VIRTUAL_ENV"** мы можем указать, где живет virtualenv проекта. Т.о. pyls будет знать, где искать установленные пакеты для автокомплита, goto и прочего.

Итак, запускаем. Предположим, у нас такой django проект:

    project
    ├── ...
    ├── my_app
    │   ├── ...
    │   ├── forms.py
    │   └── models.py
    ├── manage.py
    └── setup.cfg


Простейший файл models.py:

    from django.db import models


    class Book(models.Model):
        """
        This is docstring of Book model.
        Example for LSP demostration.
        """

        title = models.CharField(max_length=50)

и forms.py:

    from django.forms import ModelForm
    from .models import Book


    class BookForm(ModelForm):

        class Meta:
            model = Book
            fields = '__all__'

В файле setup.cfg есть секция `[flake8]`:

    [flake8]
    ignore = D202,D205,D211
    max-line-length = 99


Что же нам теперь доступно?
Из коробки, сервер предоставляет возможности [jedi](https://jedi.readthedocs.io/en/latest/), например Definitions (goto), References, автокомплит и кое-что еще.

При наведении курсора отображается docstring объекта, а так же возможные действия над ним:

![Sublime Text и Language Server Protocol (LSP): окно при наведении курсора с документацией и действиям](https://i.ibb.co/0yW1sRd/sublime-lsp-popup-with-docstring-and-actions.png
 "Sublime Text и Language Server Protocol (LSP): окно при наведении курсора с документацией и действиями")

При нажатии на Definition мы перейдем в файл и место, где класс объявлен.
При нажатии на References - увидим, где объект используется:

![Sublime Text и Language Server Protocol (LSP): References](https://i.ibb.co/26LW2ys/sublime-lsp-references.png
 "Sublime Text и Language Server Protocol (LSP): References")

Так же работает автокомплит:

![Sublime Text и Language Server Protocol (LSP): автокомплит методов](https://i.ibb.co/cb2gKDJ/sublime-lsp-autocomplete-methods.png
 "Sublime Text и Language Server Protocol (LSP): автокомплит методов")

![Sublime Text и Language Server Protocol (LSP): автокомплит полей](https://i.ibb.co/zQ6ZXHh/sublime-lsp-autocomplete-fields.png
 "Sublime Text и Language Server Protocol (LSP): автокомплит полей")

Но ошибки синтаксиса и pep8 отображаться не будут. Чтобы они проверялись, нужно установить в virtualenv с нашим python language server'ом эти пакеты:

    pip install mccabe
    pip install pyflakes
    pip install pycodestyle

Вуаля, теперь редактор выдает подсказки:

![Sublime Text и Language Server Protocol (LSP): ошибка синтаксиса](https://i.ibb.co/VYCWVtY/sublime-lsp-invalid-syntax.png
 "Sublime Text и Language Server Protocol (LSP): ошибка синтаксиса")

![Sublime Text и Language Server Protocol (LSP): сообщение об ошибке стиля кодирования](https://i.ibb.co/rph2V6X/sublime-lsp-pep8-warning.png
 "Sublime Text и Language Server Protocol (LSP): сообщение об ошибке стиля кодирования")

Напомню, что настройки для линтера автоматически берутся из setup.cfg (согласно моим настройкам pyls).
Т.е. правила `D202,D205,D211` будут игнорироваться, а максимальная длина строки будет 99, вместо дефолтной 80.

Можно еще подключить к серверу [mypy](http://mypy-lang.org/). Для этого нужен соответствующий [плагин](https://github.com/tomv564/pyls-mypy). Но это постараюсь описать в будущей статье, если руки дойдут, там тоже есть вопросы.

В итоге у нас есть работающий Python Language Server в Sublime Text 3.
Как видно, опыт не из простых, но я все еще держусь за этот редактор кода, привычка.
Да, я иногда использую Pycharm, где фишек очень и очень много. И Visual Studio Code неплох, но к sublime'у сердце прикипело что ли.

Какие могу стделать выводы:

- немного сыровато все, приходится делать PR'ы, а принимаются они долго.
- Sublime LSP не работает в правом окне (_View -> Layout -> Columns: 2_), нужно видимо опять дорабатывать
- стоит пристальнее посмотреть в сторону реализации [python language server от microsoft](https://github.com/Microsoft/python-language-server/), т.к. скорее всего тренд будет за ним.

Ну а пока получился вполне рабочий вариант, пользуюсь им в повседневной работе.

И спасибо [Григорию Петрову](https://twitter.com/grigoryvp) за его [доклад на Moscow Python](http://www.moscowpython.ru/meetup/58/pyre-type-checker/). Из него я и узнал о существовании language server protocol.
