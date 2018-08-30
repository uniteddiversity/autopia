/*global $*/

var LOADING = $('<i class="my-3 fa fa-spin fa-circle-o-notch"></i>')

$(function () {

  function addPlaceholders() {
    $('form.add-placeholders label[for]').each(function () {
      var input = $(this).next().children().first()
      if (!$(input).attr('placeholder'))
        $(input).attr('placeholder', $.trim($(this).text()))
    });
  }

  function tooltip() {
    $('[data-toggle="tooltip"]').tooltip({
      html: true,
      viewport: false,
      title: function () {
        if ($(this).attr('title').length > 0)
          return $(this).attr('title')
        else
          return $(this).next('span').html()
      }
    })
  }

  function popover() {
    $('[data-toggle="popover"]').popover({
      html: true,
      viewport: false,
      trigger: 'manual',
      placement: 'top',
      animation: false,
      title: function () {
        return $(this).next('span').html()
      },
      content: function () {
        return $(this).next('span').next('span').html()
      }
    }).on("mouseenter", function () {
      var _this = this;
      setTimeout(function () {
        if ($(_this).filter(':hover').length) {
          $(_this).popover("show");
          $($(_this).data('bs.popover')['tip']).on("mouseleave", function () {
            $(_this).popover('hide');
          });
        }
      }, 200);
    }).on("mouseleave", function () {
      var _this = this;
      setTimeout(function () {
        if (!$($(_this).data('bs.popover')['tip']).filter(':hover').length) {
          $(_this).popover("hide");
        }
      }, 200);
    });
  }

  function timeago() {
    $("abbr.timeago").timeago()
  }

  function datepickers() {
    $(".datepicker").flatpickr({altInput: true, altFormat: 'J F Y'});
    $(".datetimepicker").flatpickr({altInput: true, altFormat: 'J F Y, H:i', enableTime: true, time_24hr: true});
  }

  function resizeCommentTextareas() {
    $('textarea[id=comment_body]').click(function () {
      $(this.form).find('.btn-primary').parent().parent().removeClass('d-none')
    }).keydown(function () {
      var el = this;
      setTimeout(function () {
        el.style.cssText = 'height:4em; padding:0';
        el.style.cssText = 'height:' + el.scrollHeight + 'px';
      }, 0);
    })
  }

  $(document).ajaxComplete(function () {
    addPlaceholders()
    tooltip()
    popover()
    timeago()
    datepickers()
    resizeCommentTextareas()
  });
  addPlaceholders()
  tooltip()
  popover()
  timeago()
  datepickers()
  resizeCommentTextareas()

  $('form').submit(function () {
    $('button[type=submit]', this).attr('disabled', 'disabled').html('Submitting...');
  });

  $('[data-upload-url]').click(function () {
    var form = $('<form action="' + $(this).attr('data-upload-url') + '" method="post" enctype="multipart/form-data"><input style="display: none" type="file" name="upload"></form>')
    form.insertAfter(this)
    form.find('input').click().change(function () {
      this.form.submit()
    })
  })

  $('input[type=text].slug').each(function () {
    var slug = $(this);
    var start_length = slug.val().length;
    var pos = $.inArray(this, $('input', this.form)) - 1;
    var title = $($('input', this.form).get(pos));
    slug.focus(function () {
      slug.data('focus', true);
    });
    title.keyup(function () {
      if (start_length == 0 && slug.data('focus') != true)
        slug.val(title.val().toLowerCase().replace(/ /g, '-').replace(/[^a-z0-9\-]/g, ''));
    });
  });

  $(document).on('click', 'a.popup', function (e) {
    window.open(this.href, null, 'scrollbars=yes,width=600,height=600,left=150,top=150').focus();
    return false;
  });

  $('textarea.wysiwyg').each(function () {
    var textarea = this
    var editor = textboxio.replace(textarea, {
      css: {
        stylesheets: ['/stylesheets/app.css']
      },
      paste: {
        style: 'plain'
      },
      images: {
        allowLocal: false
      }
    });
    if (textarea.form)
      $(textarea.form).submit(function () {
        if ($(editor.content.get()).text().trim() == '') {
          editor.content.set(' ')
          $(textarea).val(' ')
        }
      })
  });

  $(document).on('click', 'a[data-confirm]', function (e) {
    $(this).removeClass('no-trigger')
    var message = $(this).data('confirm');
    if (!confirm(message)) {
      $(this).addClass('no-trigger')
      return false
    }
  });

});