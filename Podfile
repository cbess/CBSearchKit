source 'https://github.com/CocoaPods/Specs.git'
platform :osx, '10.10'

def common_pods
    pod 'FMDB', '~> 2.7.5'
    pod 'sqlite3', '3.25.3', inhibit_warnings: true
    pod 'sqlite3/fts'
    pod 'sqlite3/fts5'
end

target 'CBSearchKit' do
    common_pods
end

target 'CBSearchKitTests' do
    common_pods
end
