require 'mkmf'
require 'rbconfig'

extension_name = 'oj'
dir_config(extension_name)

parts = RUBY_DESCRIPTION.split(' ')
type = parts[0]
type = type[4..-1] if type.start_with?('tcs-')
type = 'ree' if 'ruby' == type && RUBY_DESCRIPTION.include?('Ruby Enterprise Edition')
is_windows = RbConfig::CONFIG['host_os'] =~ /(mingw|mswin)/
platform = RUBY_PLATFORM
version = RUBY_VERSION.split('.')
puts ">>>>> Creating Makefile for #{type} version #{RUBY_VERSION} on #{platform} <<<<<"

dflags = {
  'RUBY_TYPE' => type,
  (type.upcase + '_RUBY') => nil,
  'RUBY_VERSION' => RUBY_VERSION,
  'RUBY_VERSION_MAJOR' => version[0],
  'RUBY_VERSION_MINOR' => version[1],
  'RUBY_VERSION_MICRO' => version[2],
  'HAS_RB_TIME_TIMESPEC' => (!is_windows && 'ruby' == type && ('1.9.3' == RUBY_VERSION || '2' <= version[0])) ? 1 : 0,
  'HAS_ENCODING_SUPPORT' => (('ruby' == type || 'rubinius' == type) &&
                             (('1' == version[0] && '9' == version[1]) || '2' <= version[0])) ? 1 : 0,
  'HAS_NANO_TIME' => ('ruby' == type && ('1' == version[0] && '9' == version[1]) || '2' <= version[0]) ? 1 : 0,
  'HAS_RSTRUCT' => ('ruby' == type || 'ree' == type || 'tcs-ruby' == type) ? 1 : 0,
  'HAS_IVAR_HELPERS' => ('ruby' == type && !is_windows && (('1' == version[0] && '9' == version[1]) || '2' <= version[0])) ? 1 : 0,
  'HAS_EXCEPTION_MAGIC' => ('ruby' == type && ('1' == version[0] && '9' == version[1])) ? 0 : 1,
  'HAS_PROC_WITH_BLOCK' => ('ruby' == type && (('1' == version[0] && '9' == version[1]) || '2' <= version[0])) ? 1 : 0,
  'HAS_GC_GUARD' => ('jruby' != type && 'rubinius' != type) ? 1 : 0,
  'HAS_TOP_LEVEL_ST_H' => ('ree' == type || ('ruby' == type &&  '1' == version[0] && '8' == version[1])) ? 1 : 0,
  'NEEDS_RATIONAL' => ('ruby' == type &&  '1' == version[0] && '8' == version[1]) ? 1 : 0,
  'IS_WINDOWS' => is_windows ? 1 : 0,
  'SAFE_CACHE' => is_windows ? 0 : 1,
}
# This is a monster hack to get around issues with 1.9.3-p0 on CentOS 5.4. SO
# some reason math.h and string.h contents are not processed. Might be a
# missing #define. This is the quick and easy way around it.
if 'x86_64-linux' == RUBY_PLATFORM && '1.9.3' == RUBY_VERSION && '2011-10-30' == RUBY_RELEASE_DATE
  begin
    dflags['NEEDS_STPCPY'] = nil if File.read('/etc/redhat-release').include?('CentOS release 5.4')
  rescue Exception
  end
else
  dflags['NEEDS_STPCPY'] = nil if is_windows
end

dflags.each do |k,v|
  if v.nil?
    $CPPFLAGS += " -D#{k}"
  else
    $CPPFLAGS += " -D#{k}=#{v}"
  end
end
$CPPFLAGS += ' -Wall'
#puts "*** $CPPFLAGS: #{$CPPFLAGS}"
create_makefile(extension_name)

%x{make clean}
