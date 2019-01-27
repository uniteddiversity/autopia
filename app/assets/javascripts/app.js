/*global $*/

var LOADING = '<i class="my-3 fa fa-spin fa-circle-o-notch"></i>'

function nl2br(str) {
  return str.replace(/(?:\r\n|\r|\n)/g, '<br>');
}

function br2nl(str) {
  return str.replace(/<br>/g, "\r\n");
}


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
      title: function () {
        if ($(this).attr('title').length > 0)
          return $(this).attr('title')
        else
          return $(this).next('span').html()
      }
    })
  }

  function timeago() {
    $("abbr.timeago").timeago()
  }

  function datepickers() {
    $(".datepicker").flatpickr({altInput: true, altFormat: 'J F Y'});
    $(".datetimepicker").flatpickr({altInput: true, altFormat: 'J F Y, H:i', enableTime: true, time_24hr: true});
  }

  function resizeCommentTextareas() {
    $('[id=comment_subject], [id=comment_body]').focus(function () {
      $(this.form).find('.btn-primary').parent().parent().removeClass('d-none')
    })
    autosize($('textarea[id=comment_body]'));
  }

  $(document).ajaxComplete(function () {
    addPlaceholders()
    tooltip()
    timeago()
    datepickers()
    resizeCommentTextareas()
  });
  addPlaceholders()
  tooltip()
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