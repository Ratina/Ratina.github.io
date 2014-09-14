---
layout: post
title:  "使用Cython开发Python的C扩展"
date:   2014-07-31 17:17:45
categories: Python Cython
---

现在Python和C的互操作已不是什么难事，方法很多，比如使用Python的C扩展API，比如使用cdll，各有自己擅长的应用场景。

但是对于Cython，一直是存有偏见的，以为它只是Python的一个实现和它的超集，没有想过它会可以直接生成Python的C扩展，并和Python交互。

直到今天翻看Kivy的源码，才发现Kivy与移动端交互的原理正是使用Cython开发的Python扩展。
[ ](https://github.com/kivy/kivy/blob/master/kivy/lib/gstplayer/_gstplayer.h)

{% highlight C %}
// 摘自https://github.com/kivy/kivy/blob/master/kivy/lib/gstplayer/_gstplayer.h
#include <glib.h>
#include <gst/gst.h>
//...
static gulong c_appsink_set_sample_callback(GstElement *appsink, appcallback_t callback, PyObject *userdata)
{
    callback_data_t *data = (callback_data_t *)malloc(sizeof(callback_data_t));
    if ( data == NULL )
        return 0;
    data->callback = callback;
    data->bcallback = NULL;
    data->userdata = userdata;
    strcpy(data->eventname, "pull-sample");

    Py_INCREF(data->userdata);

    g_object_set(G_OBJECT(appsink), "emit-signals", TRUE, NULL);

    return g_signal_connect_data(
            appsink, "new-sample",
            G_CALLBACK(c_on_appsink_sample), data,
            c_signal_free_data, 0);
}
//...
{% endhighlight %}
<br />
{% highlight cython %}
# 摘自https://github.com/kivy/kivy/blob/master/kivy/lib/gstplayer/_gstplayer.pyx
cdef extern from '_gstplayer.h':
#...
    gulong c_appsink_set_sample_callback(GstElement *appsink,
            appcallback_t callback, void *userdata)
#...
def _gst_init():
    if gst_is_initialized():
        return True
    cdef int argc = 0
    cdef char **argv = NULL
    cdef GError *error
    if not gst_init_check(&argc, &argv, &error):
        msg = 'Unable to initialize gstreamer: code={} message={}'.format(
                error.code, <bytes>error.message)
        raise GstPlayerException(msg)
#...
{% endhighlight %}