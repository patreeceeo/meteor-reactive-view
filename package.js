Package.describe({
  summary: "An MV* View class for Meteor"
});

Package.on_use(function (api) {
  api.use('coffeescript', ['client']);
  api.use('ui', ['client']);
  api.add_files('lib/reactive_view.coffee', ['client']);
  api.export('ReactiveView');
});

Package.on_test(function (api) {
  api.use('bview');
});
