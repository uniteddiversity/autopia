/*global $*/

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
          return $(this).next().html()
      }
    })
  }

  function timeago() {
    $("abbr.timeago").timeago()
  }
  
  function datepickers() {
    $(".datepicker").flatpickr();
    $(".datetimepicker").flatpickr({enableTime: true, time_24hr: true});
  }

  $(document).ajaxComplete(function () {
    addPlaceholders()
    tooltip()
    timeago()
    datepickers()
  });
  addPlaceholders()
  tooltip()
  timeago()
  datepickers()

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

  if ($('label[for=account_poc]').length > 0)
    $('label[for=account_poc]').html($('label[for=account_poc]').html().replace('person of colour', '<a target="_blank" href="https://en.wikipedia.org/wiki/Person_of_color">person of colour</a>'))

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
    var textarea = this;
    var summernote = $('<div class="summernote"></div>');
    $(summernote).insertAfter(this);
    $(summernote).summernote({
      styleWithSpan: false,
      toolbar: [
        ['view', ['codeview', 'fullscreen']],
        ['style', ['style']],
        ['font', ['bold', 'italic', 'underline', 'clear']],
        ['color', ['color']],
        ['para', ['ul', 'ol', 'paragraph']],
        ['height', ['height']],
        ['table', ['table']],
        ['insert', ['link', 'picture', 'video']],
      ],
      height: 300,
      codemirror: {theme: 'monokai'},
    });
    $(textarea).prop('required', false);
    $(summernote).code($(textarea).val());
    $(textarea).hide();
    $(textarea.form).submit(function () {
      $(textarea).val($(summernote).code());
    });
  });

  $(document).on('click', 'a[data-confirm]', function (e) {
    $(this).removeClass('no-trigger')
    var message = $(this).data('confirm');
    if (!confirm(message)) {
      $(this).addClass('no-trigger')
      return false
    }
  });

  $(document).on('click', "a[href^='/verdicts/create']", function (e) {
    $(this).removeClass('no-trigger')
    var reason = prompt('Explain your decision ('+ ($(this).attr('data-require-reason') ? 'REQUIRED' : 'optional') + ')');
    if (reason == null) {
      $(this).addClass('no-trigger')
      return false
    } else {
      $(this).attr('href', $(this).attr('href') + '&reason=' + ((reason == 'undefined' || reason == 'null') ? '' : reason))
    }
  });

});