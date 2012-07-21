use inc::Module::Install;
name 'WordCounter';
all_from 'lib/WordCounter.pm';

requires 'mojo';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
