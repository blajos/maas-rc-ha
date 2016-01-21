require 'spec_helper'
describe 'pgpool' do

 shared_examples 'a Linux OS with defaults' do
    it {
      should contain_class('pgpool')
      should contain_class('pgpool::package')
      should contain_package('pgpool').
        with_name("#{pkg_name}").
        with_ensure('present')
      should contain_class('pgpool::config')
      should contain_file("#{config_path}/pgpool.conf").
        with_ensure('file').
        with_owner('postgres').
        with_group('postgres')
      should contain_file("#{defaults_path}/#{pkg_name}").
        with_ensure('file').
        with_owner('postgres').
        with_group('postgres')
      should contain_class('pgpool::service')
      should contain_service('pgpool').
        with_ensure('running')
      should contain_exec('pgpool_reload')
    }
  end

  context 'on RedHat' do
    let (:facts) { {
      :kernel          => 'Linux',
      :osfamily        => 'RedHat',
      :operatingsystem => 'CentoOS',
      :concat_basedir  => '/tmp'
    } }
    let(:config_path) { '/etc/pgpool-II-93' }
    let(:defaults_path) { '/etc/sysconfig' }
    let(:pkg_name) { 'pgpool-II-93' }
    it_behaves_like 'a Linux OS with defaults' do
    end
  end

  context 'on Debian' do
    let (:facts) { {
      :kernel          => 'Linux',
      :osfamily        => 'Debian',
      :operatingsystem => 'Debian',
      :concat_basedir  => '/tmp'
    } }
    let(:config_path) { '/etc/pgpool2' }
    let(:defaults_path) { '/etc/default' }
    let(:pkg_name) { 'pgpool2' }
    it_behaves_like 'a Linux OS with defaults' do
    end
  end

  context 'on RedHat with Custom package and paths' do
    let (:facts) { {
      :kernel          => 'Linux',
      :osfamily        => 'RedHat',
      :operatingsystem => 'CentoOS',
      :concat_basedir  => '/tmp'
    } }
    let(:defaults_path) { '/etc/sysconfig' }
    let(:params) { {
      :config_dir   => '/etc/pgpool-II',
      :package_name => 'pgpool-II-pg93',
      :service_name => 'pgpool'
    } }
    it {
      should contain_class('pgpool')
      should contain_class('pgpool::package')
      should contain_package('pgpool').
        with_name(params[:package_name]).
        with_ensure('present')
      should contain_class('pgpool::config')
      should contain_file("#{params[:config_dir]}/pgpool.conf").
        with_ensure('file').
        with_owner('postgres').
        with_group('postgres')
      should contain_file("#{defaults_path}/#{params[:service_name]}").
        with_ensure('file').
        with_owner('postgres').
        with_group('postgres')
      should contain_class('pgpool::service')
      should contain_service('pgpool').
        with_ensure('running')
      should contain_exec('pgpool_reload')
    }

  end
end
