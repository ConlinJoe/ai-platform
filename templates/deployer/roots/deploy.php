<?php

declare(strict_types=1);

namespace Deployer;

/**
 * AI Development Harness Deployer stack.
 * Profile: roots
 *
 * AI_PLATFORM_DEPLOYER_STACK=roots
 *
 * Installing or configuring this file does not authorize deployment.
 * Host, repository, and SSH values live in deploy/hosts.yaml.
 */

require 'recipe/composer.php';

$hosts = __DIR__ . '/deploy/hosts.yaml';
if (!is_file($hosts)) {
    fwrite(STDERR, "Missing deploy/hosts.yaml. Copy deploy/hosts.yaml.example and fill in server values.\n");
    fwrite(STDERR, "Configuring hosts does not authorize deployment.\n");
    exit(1);
}

import($hosts);

set('keep_releases', 5);
set('git_tty', false);
set('public_path', 'web');
set('shared_files', ['.env']);
set('shared_dirs', ['web/app/uploads']);
set('writable_dirs', ['web/app/uploads']);
set('theme_path', '{{THEME_PATH}}');

// Document root is web/. Point the web server at current/web.
// Sage theme build runs on the server in theme_path. If theme_path is
// still CHANGE_ME, the build is skipped. Set the actual theme directory
// in this file or override it in deploy/hosts.yaml.
//
// This recipe does not run database imports, search-replace, or
// provision tasks.

desc('Build Sage theme assets');
task('sage:build', function () {
    $theme = get('theme_path');
    if (!is_string($theme) || $theme === '' || str_contains($theme, 'CHANGE_ME')) {
        writeln('Skipping Sage build: set theme_path to the theme directory relative to the project root.');
        return;
    }

    run('cd {{release_path}}/{{theme_path}} && npm ci && npm run build');
});

desc('Deploy Bedrock/Sage');
task('deploy', [
    'deploy:prepare',
    'deploy:vendors',
    'sage:build',
    'deploy:publish',
]);
