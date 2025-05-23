#!/bin/bash

exec=$1
if [ -z "$exec" ]; then
	exec=famine
fi

signature="Famine version 1.0 (c)oded by alexafer-jdecorte"
target="/tmp/test"
logfile="famine.log"

echo "Testing $exec with target $target"

if [ ! -f "$exec" ]; then
	echo "Executable $exec not found"
	exit 1
fi

setup()
{
	rm -rf $target
	mkdir -p $target
}

is_all_infected()
{
    find "$target" -type f | while read -r file; do
        if ! (file "$file" | grep -q "ELF 64-bit"); then
            continue
        fi

        # skip if pie, since it's not mandatory
        if (file "$file" | grep -q "LSB pie"); then
            continue
        fi

        if strings "$file" | grep -q "$signature"; then
            echo "✅ Signature found in $file" >> $logfile
        else
            assertEquals "Signature not found in $file" 0 $?
            echo "❌ Signature not found in $file" >> $logfile
        fi
    done
}

run_famine()
{
    ./$exec
    local ret=$?
    assertEquals "'$exec' did not exit cleanly" 0 "$ret"
    if [ $ret -ne 0 ]; then
        exit 1
    fi
}

# Tests ------------------------------------------------------------

test_famine()
{
    setup
    
    # populate with /user/bin, /usr/sbin and /usr/local/bin
    cp -r test/sample_binaries $target
    cp -r /usr/bin/ $target
    cp -r /usr/sbin/ $target
    
    mkdir -p $target/bin2
    cp -r /usr/local/bin/ $target/bin2

    run_famine
    assertEquals "'$exec' did not exit cleanly" 0 $?
    is_all_infected
}


. shunit2