---
layout: post
title:  "delphi tips"
date:   2020-10-28 12:00:00
categories: delphi programming
---

## Blending

I found some info at [blend bitmap]. It's using a Graphics32 library. I didn't examined for now.
Another interesting tip is about blending one control on form - [alpha blend control]. It is basically about to put a form under a control. That's because alpha blending can be set only on form.

{% highlight delphi %}
  P := TWinControl(Sender).ClientToScreen(Point(0,0));
  frm := TForm.Create(nil);
  TWinControl(Sender).Parent := frm;
  frm.BorderStyle := bsNone;
  frm.AlphaBlend := true;
  frm.AlphaBlendValue := 128;
  frm.AutoSize := true;
  frm.Left := P.X;
  frm.Top := P.Y;
  frm.Position := poDesigned;
  frm.Show;
{% endhighlight delphi %}


## Multiple hints

Here [hints on control regions] I have found an easy way to support multiple hints in one control. It is build up inside delphi alrady. All what is needed is to create handler for CM_HINTSHOW message. Message is of TCMHintShow type and by specifing CursorRect and HintStr you can tell what hint and where will be displayed. It works fine even if regions are one next to another.


## Inline declarations

[inline declaration] is part of newer delphi versions, probably from XE3. When one codes short methods they this feature is not so important. But use them in for loop is handy:

{% highlight delphi %}
  for var I: Integer := 1 to 10 do ...
  for var Item: TItemType in Collection do...
{% endhighlight delphi %}


Especially when taking advantage of type inference:

{% highlight delphi %}
  for var I := 1 to 10 do ...
  for var Item in Collection do ...
{% endhighlight delphi %}



# Links:

* [blend bitmap]
* [alpha blend control]
* [hints on control regions]
* [inline declaration]


[blend bitmap]: https://stackoverflow.com/questions/29044637/how-to-fillrect-using-a-blend-mode-like-multiply-and-not-just-a-simple-transpar
[alpha blend control]: https://stackoverflow.com/questions/12627526/is-it-possible-to-alpha-blend-a-vcl-control-on-a-tform
[hints on control regions]:https://stackoverflow.com/questions/43321926/make-showhint-work-on-custom-control-with-several-different-rects-each-with-the
[inline declaration]:http://docwiki.embarcadero.com/RADStudio/Rio/en/Inline_Variable_Declaration