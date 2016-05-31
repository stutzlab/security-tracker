
var gulp  = require('gulp');
var gzip  = require('gulp-gzip');
var rename  = require('gulp-rename');
var inlinesource = require('gulp-inline-source');

// var watcher = gulp.watch('src/captive/*', ["prepare"]);
// watcher.on("change", function(event) {
//   console.log("File " + event.path + " was " + event.type + ", running tasks...");
// });

gulp.task("default", ["prepare"], function() {
  console.log("Build Finished");
});

gulp.task('prepare', function () {
    return gulp.src('src/captive/index.html')
        .pipe(inlinesource())
        .pipe(gzip({gzipOptions:{level:9}, extension:'gz', append:true}))
        .pipe(rename("bundle_ui.gz"))
        .pipe(gulp.dest('data/homie'));
});
