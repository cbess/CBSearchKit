source 'https://github.com/CocoaPods/Specs.git'
platform :osx, '10.15'

def common_pods
    # https://github.com/ccgus/fmdb
    pod 'FMDB', :git => 'https://github.com/ccgus/fmdb.git', :commit => 'd31d362c'
    # https://github.com/clemensg/sqlite3pod
    pod 'sqlite3', '3.38.0', inhibit_warnings: true
    pod 'sqlite3/fts'
    pod 'sqlite3/fts5'
end

target 'CBSearchKit' do
    common_pods
end

target 'CBSearchKitTests' do
    common_pods
end
