/**
 * CLASS DESCRIPTION
 */
wesabe.$class('<%= name %>', <%= superclass_name %>, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    // INSTANCE VARIABLES
    // _fooElement: null,
    // _doneButton: null,

    init: function(element) {
      $super.init.call(this, element);

      // SAVE ELEMENTS FOR LATER REFERENCE
      // this._fooElement = element.find('.foo');

      // REGISTER ANY CHILD WIDGETS CREATED
      // this._doneButton = new wesabe.views.widgets.Button(element.find('.button.done'));
      // this._doneButton.bind('click', this.onDoneButtonClick, this);
      // this.registerChildWidget(this._doneButton);
    }

    // INSTANCE METHODS
    // onDoneButtonClick: function() {
    //   ...
    // }
  });
});
