
$(function () {

  $('[data-toggle="tooltip"]').tooltip()

  if ($('label[for=account_poc').length > 0)
    $('label[for=account_poc').html($('label[for=account_poc').html().replace('person of colour', '<a target="_blank" href="https://en.wikipedia.org/wiki/Person_of_color">person of colour</a>'))

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

  $(document).on('click', 'a[data-confirm]', function (e) {
    var message = $(this).data('confirm');
    if (!confirm(message)) {
      e.preventDefault();
      e.stopped = true;
    }
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

});