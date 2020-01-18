---
layout: post
title:  "Powershell tips"
date:   2020-01-18 12:00:00
categories: programming powershell
---

Here I will collect some interesting things about powershell, just to keep it in one place. Quick and quite comprehensive info can be found at [ss64-powershell-syntax].

* it is good to update help, so one can use Get-Help as a first hand information
{% highlight cmd %}
PS C:\> Update-Help
PS C:\> Get-Help Set-ExecutionPolicy
{% endhighlight %}


* in case to run script from shared location, change of execution policy is needed - for current command or permanently(see all possiblities using Get-Help)
{% highlight cmd %}
PS C:\> Set-ExecutionPolicy Bypass -Scope Process -Force; \\share\somescript.ps1
PS C:\> Set-ExecutionPolicy -ExecutionPolicy bypass -Scope CurrentUser
{% endhighlight %}


* except commont assignment
{% highlight cmd %}
PS C:\> $a = 5
PS C:\> $a
5
PS C:\> $a +=2
PS C:\> $a
7
{% endhighlight %}


* in powershell exists aswell multiassignmet - see [about-assigment-operators] on the end of page
{% highlight cmd %}
PS C:\> $a, $b = 1, 2
PS C:\> $a, $b
1
2
PS C:\>
{% endhighlight %}


* I has found more about it due to [zip-function] - to be assigned variable $a1 can be array and assignment assign first member of array to $x and rest of array to $a1. It quit ressamble fsharp head::tail match expression. Only don't know if such a construction is somewhat effective or just rest of array is copied.  Btw. arrays in powershell are immutable.
{% highlight cmd %}
function Zip($a1, $a2) {
    while ($a1) {
        $x, $a1 = $a1
        $y, $a2 = $a2
        [tuple]::Create($x, $y)
    }
}
{% endhighlight %}


* powershell functions are first class citiziens - they can be assigned to variable and call by prepending call operator & in front of it - see [ss64-powershell-calloperator]
{% highlight cmd %}
PS C:\> $a = { param($x,$y) Write-Host $x $y}
PS C:\> &$a 1 2
1 2
PS C:\> & { param($x,$y) Write-Host $x $y}
PS C:\> & { param($x,$y) Write-Host $x $y} 1 2
1 2
{% endhighlight %}


* you can get curried function too, important is to use GetNewClosure(), I have found more info about functional programming here [lambda-functions], [functional-programming-in-powershell_1], [functional-programming-in-powershell_2]

{% highlight cmd %}
PS C:\> $b = {param ($x) &$a 5 $x}.GetNewClosure()
PS C:\> &$b 7
5 7
{% endhighlight %}



* [ss64-powershell]
* [ss64-powershell-syntax]
* [ss64-powershell-calloperator]
* [about-assigment-operators]
* [zip-function]

* [create-powershell-objects]
* [get-object-method-code]
* [command-info-objects]

* [lambda-functions]
* [functional-programming-in-powershell_1]
* [functional-programming-in-powershell_2]


[ss64-powershell]: https://ss64.com/ps/
[ss64-powershell-syntax]: https://ss64.com/ps/syntax.html
[ss64-powershell-calloperator]:https://ss64.com/ps/call.html
[about-assigment-operators]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_assignment_operators?view=powershell-5.1
[zip-function]: https://stackoverflow.com/questions/25191803/powershell-cli-foreach-loop-with-multiple-arrays

[create-powershell-objects]: https://ridicurious.com/2018/10/15/4-ways-to-create-powershell-objects/
[get-object-method-code]: https://stackoverflow.com/questions/29562252/extracting-viewing-the-value-of-a-scriptmethod
[command-info-objects]: https://livebook.manning.com/book/windows-powershell-in-action-third-edition/chapter-10/52

[lambda-functions]: https://www.powershellmagazine.com/2013/12/23/simplifying-data-manipulation-in-powershell-with-lambda-functions/
[functional-programming-in-powershell_1]: https://medium.com/swlh/functional-programming-in-powershell-876edde1aadb
[functional-programming-in-powershell_2]: http://alexfalkowski.blogspot.com/2012/08/functionalprogramming-in-powershell.html
