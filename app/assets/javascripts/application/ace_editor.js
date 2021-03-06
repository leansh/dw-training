var mumuki = mumuki || {};

(function (mumuki) {
  function createAceEditors() {
    var editors = $(".editor").map(function (index, textarea) {
      var builder = new mumuki.editor.AceEditorBuilder(textarea);
      builder.setupEditor();
      builder.setupOptions();
      builder.setupSubmit();
      builder.setupLanguage();
      return builder.build();
    });

    if (editors[0]) {
      editors[0].focus();
    }
    return editors;
  }

  function onSelectUpdateAceEditor() {
    $("#exercise_language_id").change(updateAceEditorLanguage);
  }

  function updateAceEditorLanguage() {
    var language = $("#exercise_language_id").find(":selected").html() || $('#exercise_language').val();
    if (language !== undefined) {
      mumuki.page.dynamicEditors.forEach(function (e) {
        setEditorLanguage(e, language);
      })
    }
  }

  function setEditorLanguage(editor, language) {
    editor.getSession().setMode("ace/mode/" + language.toLowerCase())
  }

  mumuki.editor = mumuki.editor || {};
  mumuki.editor.setupAceEditors = setEditorLanguage;

  mumuki.page = mumuki.page || {};
  mumuki.page.dynamicEditors = [];
  mumuki.page.editors = [];

  $(document).on('ready page:load', function () {
    mumuki.page.editors = createAceEditors();
    updateAceEditorLanguage();
    onSelectUpdateAceEditor();
  });
})(mumuki);