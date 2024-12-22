---
layout: post
title:  "Create empty web project with feliz"
date:   2024-12-22 01:00:00
categories: feliz fable js javascript fsharp f# dotnet
---

I have started to play with making front app in f# and transpile it to js using fable.
Main source of inspiration was the [elmish book] by [Zaid Ajaj]. 
The [feliz template] can be used to create scaffolding of a new project. But let's do
it from command line with help of [fable start a new project] and [fable adapt project for browser].
Different technologies are involved here and I want to have a sense whats going on.


New project directory:
~~~cmd
mkdir tictactoe
cd tictactoe
~~~


Manifest file:
~~~cmd
dotnet new tool-manifest
~~~
This command creates directory .config with dotnet-tools.json file. There are listed command 
line tools project needs together with their versions there.
Real location of installed files on linux depends if installed globally (~/.dotnet/tools)
or locally (~/.nuget/packages).
Let's install fable compiler and femto package manager. Femto is optional, but it's advantage is 
it installs both .net packages and js packages .net packages depends on.


Project tools:
~~~cmd
dotnet tool install fable
dotnet tool install femto
~~~
Update tool can be used later to promote tools to newer version.


Js project:
~~~cmd
npm init -y
npm i -D vite
~~~
Npm (node package manager) creates files package.json and packages-lock.json. It is needed now
because later femto will be used which internally use npm.
Vite is a debugger and builder of js project.


F# project:
~~~cmd
mkdir src
cd src
dotnet new console -lang F#
rm -rf obj
mv src.fsproj app.fsproj
~~~
Rename is done just to have different name (there is no switch to create project in actual directory with given name).


Dependencies for f# project:
~~~cmd
dotnet femto install Fable.Core
dotnet femto install Fable.Browser.Dom
dotnet femto install Fable.Elmish.React 
dotnet femto install Feliz
dotnet femto install Thoth.Json
dotnet femto install Fable.SimpleHttp
dotnet femto install Fable.DateFunctions
~~~
Whatever dependencies can be added. When femto is not used you can add package to f# project via dotnet add package<name>
and appropriate js script package with use of npm (you need first to return to parent directory where npm files resides).


To finish project to something usable follow [fable adapt project for browser] to add index.html file and to modify
Program.fs.

Recapitulation - there are included dotnet tools, dotnet project and its packages and node project and its packages. Femto takes care
for both dotnet and js packages but both can be manage independetly at the same time by project specific package
managers.

Building js:
~~~code
#!/bin/bash
dotnet fable src --run npx vite build
~~~

Debugging:
~~~code
#!/bin/bash
# based on https://github.com/fable-compiler/Fable/issues/3631  --verbose prevent freezing of fable
# other workaround was run vit separately and not via fable
dotnet fable watch src --verbose --run npx vite
~~~

* [fable start a new project]
* [fable adapt project for browser]
* [feliz template]
* [elmish book]
* [Zaid Ajaj]

[fable start a new project]: https://fable.io/docs/getting-started/your-first-fable-project.html
[fable adapt project for browser]: https://fable.io/docs/getting-started/javascript.html#browser
[feliz template]: https://zaid-ajaj.github.io/Feliz/#/Feliz/ProjectTemplate
[elmish book]: https://zaid-ajaj.github.io/the-elmish-book/#/
[Zaid Ajaj]: https://github.com/Zaid-Ajaj
