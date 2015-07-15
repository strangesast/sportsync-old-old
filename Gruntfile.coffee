module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)
  grunt.initConfig
    coffee:
      src:
        expand: true
        cwd: 'src/'
        src: '**/*.coffee'
        dest: 'app/'
        ext: '.js'
      assets:
        expand: true
        cwd: 'assets/coffee/'
        src: '*.coffee'
        dest: 'public/js/'
        ext: '.js'
    jade:
      options:
        pretty: true
      template:
        options:
          client: true
        expand: true
        cwd: 'views'
        src: ['**/_*.jade']
        dest: 'public/jade/'
        ext: '.js'
    less:
      all:
        expand: true
        cwd: 'assets/less/'
        src: '**/*.less'
        dest: 'public/css/'
        ext: '.css'
    watch:
      coffee:
        files: '**/*.coffee'
        tasks: ['coffee:src', 'coffee:assets']
      less:
        files: 'assets/css/**/*.less'
        tasks: ['less:all']
      jade:
        files: 'views/_*.jade'
        tasks: ['jade']
    nodemon:
      dev:
        script: 'bin/www.js'
        options:
          cwd: 'app/'
          ignore: ['public']
          delay: 800
    concurrent:
      dev: 
        tasks: ['watch', 'nodemon:dev']

        options:
          logConcurrentOutput: true

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-nodemon'

  grunt.registerTask('default', ['coffee', 'jade', 'less']);
  grunt.registerTask('w', ['concurrent:dev']);
