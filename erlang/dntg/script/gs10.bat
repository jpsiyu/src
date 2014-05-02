cd ../
#del ebin\*.beam
erl -noshell -s make all -s init stop
cd config
erl +P 1024000 +K true -smp disable -name yxyz10@127.0.0.1 -setcookie gs -boot start_sasl -config gs -pa ../ebin -s gs start -extra 192.168.1.61 9010 10
