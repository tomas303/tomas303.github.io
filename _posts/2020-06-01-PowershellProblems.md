---
layout: post
title:  "Powershell performance problems"
date:   2020-06-01 12:00:00
categories: programming powershell
---

I found it by hard way like many others before me. Powershell has it's performance limitations and
most of them are real traps waiting for newcomers like me. I quickly developed script for checking
couple of things in our logs. Test log's size was up to tens of MB and scripts run minutes.
Ok - it was something you can live with. But then I needed to process logs of size up to hundreds MB
and run time jumped over couple of hours. I consulted uncle google and in my case slowness was
caused by 3 factors:


1. by how file was read
2. in some cases by use += operator to extend array
3. by using function


## reading file

# Get-Content cmdlet - it is usually recomended to not use for big files

{% highlight cmd %}
measure-command { (Get-Content -path .\Test.log) | % { write-output $_ } } | Select-Object -Property TotalSeconds

TotalSeconds
------------
   3,9129402
{% endhighlight %}


# Get-Content cmdlet with raw parameter and split by line ends - need to fit in memory

{% highlight cmd %}
measure-command { (Get-Content -path .\Test.log -raw) -split "`n" | % { write-output $_ } } | Select-Object -Property TotalSeconds

TotalSeconds
------------
   3,1242313
{% endhighlight %}


# use StreamReader based on [PowerShell scripting performance considerations]

{% highlight cmd %}
measure-command {
>> try
>> {
>>     $stream = [System.IO.StreamReader]::new('C:\Test.log')
>>     while ($line = $stream.ReadLine()) { write-output $_ }
>> }
>> finally
>> {
>>     $stream.Dispose()
>> }
>> } | Select-Object -Property TotalSeconds

TotalSeconds
------------
   2,8871127
{% endhighlight %}


# and winner - variant of switch command I didn't know existed

{% highlight cmd %}
measure-command { switch -file .\Test.log { default { write-output $_ } } } | Select-Object -Property TotalSeconds

TotalSeconds
------------
   2,4991266
{% endhighlight %}



## extend array
Array is immutable in .net so when += operator is used new array is created. So it is clear that use of array
for storing more values is performance killer.

# Use array

{% highlight cmd %}
measure-command {
>> $arr = @()
>> $i = 0
>> do { $i++; $arr += $i} while ( $i -lt 10000)
>> } | Select-Object -Property TotalSeconds

TotalSeconds
------------
   2,1282633
{% endhighlight %}


# Use array list

{% highlight cmd %}
measure-command {
>> $arr = [System.Collections.ArrayList]::new()
>> $i = 0
>> do { $i++; $arr.Add($i)} while ( $i -lt 10000)
>> } | Select-Object -Property TotalSeconds
>>

TotalSeconds
------------
   0,0449895
{% endhighlight %}


## using function
It is probably this [function call overhead bug]. When script is supposed to run against big number of data one can
manually inline code of most time consuming functions. But it is far from ideal.

# with calling function

{% highlight cmd %}
measure-command {
>> function Test {
>>     param( [int]$i )
>>     $i * 2
>> }
>>
>> $i = 0
>> $t = 0
>> do { $i++; $t += (Test $i)} while ( $i -lt 10000)
>> } | Select-Object -Property TotalSeconds
>>

TotalSeconds
------------
   0,2889852
{% endhighlight %}


# with calling code directly

{% highlight cmd %}
measure-command {
>> $i = 0
>> $t = 0
>> do { $i++; $t += ($i * 2)} while ( $i -lt 10000)
>> } | Select-Object -Property TotalSeconds
>>

TotalSeconds
------------
    0,027523
{% endhighlight %}


There is a bit more things to pay attention to on [PowerShell scripting performance considerations].

* [why-get-content-aint-yer-friend]
* [PowerShell scripting performance considerations]
* [function call overhead bug]

[why-get-content-aint-yer-friend]: https://powershell.org/2013/10/why-get-content-aint-yer-friend
[PowerShell scripting performance considerations]: https://docs.microsoft.com/en-us/windows-server/administration/performance-tuning/powershell/script-authoring-considerations
[function call overhead bug]: https://github.com/PowerShell/PowerShell/issues/8482
