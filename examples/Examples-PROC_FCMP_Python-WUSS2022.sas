* Set directory to save functions;
options cmplib=work.funcs;

* Input data;

filename outxlsx 'XXXX\WUSS22\privateschools2122.xlsx';
proc http
    url='https://www.cde.ca.gov/ds/si/ps/documents/privateschools2122.xlsx'
    method='get'
    out=outxlsx
;
run; quit;

libname schools xlsx 'XXXX\WUSS22\privateschools2122.xlsx';
data schools_sds(rename=(cds_code_char=cds_code));
    length cds_code_char $ 14;
    set schools.'2021-22 Private School Data$A3:0'n;
    full_address = catx(', ', street, city, state, zip);
    cds_code_char = put(cds_code, z14.);
    drop cds_code;
run;
libname schools clear;


/*--------------------------------+
| SAS ONLY "Hello World" examples |
+--------------------------------*/

* 1. SAS hello function;
proc fcmp outlib=work.funcs.sas;
    function hello_from_sas(name $) $ 25;
        Message = 'Hello, '||name;
        return(Message);
    endfunc;
run;

data _null_;
    message = hello_from_sas('WUSS');
    put message=;
run;

%put %sysfunc(hello_from_sas(WUSS));

* 2. SAS Hello/Goodbye routine;
proc fcmp outlib=work.funcs.sas;
    subroutine hello_goodbye(name $, greeting $, farewell $);
        outargs greeting, farewell;
        greeting = 'Hello, '||name;
        farewell = name||', Goodbye!';
    endsub;
run;

data _null_;
    length message1 message2 $ 25;
    call hello_goodbye('WUSS', message1, message2);
    put message1 / message2;
run;


/*----------------------------------+
| SAS/Python "Hello World" examples |
+----------------------------------*/

* 1. Inline FCMP Python hello;
proc fcmp;
    length message $ 25;
    declare object py(python);

    submit into py;
        def hello():
            """Output: hello_return_value"""
            return 'Hello'
    endsubmit;

    rc = py.publish();
    rc = py.call('hello');

    message = py.results['hello_return_value'];
    file log;
    put message=;
run;

* 2. SAS/Python function hello, with random module;
proc fcmp outlib=work.funcs.python;
    function greetings_from_python() $ 25;
        length message $ 25;
        declare object py(python);

        submit into py;
            def greetings():
                """Output: greetings_return_value"""
                import random
                greeting = random.choice(
                    ['Hello', "What's up", 'How do you do?']
                )
                return greeting
        endsubmit;

        rc = py.publish();
        rc = py.call('greetings');
        message = py.results['greetings_return_value'];
        return(message);
    endfunc;
run;

data _null_;
    message = greetings_from_python();
    put message=;
run;


* 3. SAS FCMP Python function hello, with faker;
proc fcmp outlib=work.funcs.python;
    subroutine personal_greetings_from_python(greeting $, name $);
        length greeting $ 25 name $ 25;
        outargs greeting, name;
        declare object py(python);

        submit into py;
            def personal_greetings():
                """Output: greeting_return_value, name_return_value"""
                import random
                from faker import Faker
                greeting = random.choice(
                    ['Hello,', "What's up,", 'How do you do,']
                )
                fake = Faker()
                name = fake.name()
                return greeting, name
        endsubmit;

        rc = py.publish();
        rc = py.call('personal_greetings');
        greeting = py.results['greeting_return_value'];
        name = py.results['name_return_value'];
    endsub;
run;

data _null_;
    length greeting name $ 25;
    call personal_greetings_from_python(greeting, name);
    put greeting name;
run;


* 4. Passing a parameter to Python;
proc fcmp outlib=work.funcs.python;
    function data_driven_hello_from_python(name $) $ 25;
        length Message $ 25;
        declare object py(python);

        submit into py;
            def data_driven_hello(name):
                """Output: hello_return_value"""
                return f'Hello {name}!'
        endsubmit;

        rc = py.publish();
        rc = py.call('data_driven_hello', name);
        message = py.results['hello_return_value'];
        return(message);
    endfunc;
run;

data greetings;
    set sashelp.class;
    message = data_driven_hello_from_python(name);
run;

proc print data=greetings;
    var message;
run;


/*---------------------------+
| Validating Email Addresses |
+---------------------------*/

* 1. Normalize email addresses;
proc fcmp outlib=work.funcs.python;
    function get_normalized_email(email $) $ 100;
        declare object py(python);
        length normalized_email $ 100 Exception_Encountered $ 500;

        submit into py;
            def normalize_email(e):
                """Output: normalize_email_return_value, exception"""
                from email_validator import (
                    validate_email, EmailNotValidError
                )
                try:
                    normalized_email = validate_email(
                        e, check_deliverability=False
                    )
                    return normalized_email.email, ' '
                except EmailNotValidError:
                    return ' ', repr(e)
        endsubmit;

        rc = py.publish();
        rc = py.call('normalize_email', email);

        Exception_Encountered = py.results['exception'];
        if not missing(Exception_Encountered) then
            put Exception_Encountered=;

        normalized_email = py.results['normalize_email_return_value'];
        return(normalized_email);
    endfunc;
run;

data normalized_emails;
    set schools_sds;
    normalized_email = get_normalized_email(primary_email);
run;

proc print data=normalized_emails;
    var primary_email normalized_email;
    where primary_email NE normalized_email;
run;


/*----------+
| Geocoding |
+----------*/

%let MAPQUEST_API_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXX';

proc fcmp outlib=work.funcs.python;
    subroutine get_lat_long(address $, key $, lat, long);
        outargs lat, long;
        declare object py(python);

        submit into py;
            def geocode(a, k):
                """Output: latitude_return_value, longitude_return_value"""
                import geocoder
                g = geocoder.mapquest(a, key = k)
                lat = g.latlng[0]
                long = g.latlng[1]
                return lat, long
        endsubmit;

        rc = py.publish();
        rc = py.call('geocode', address, key);

        lat = py.results['latitude_return_value'];
        long = py.results['longitude_return_value'];
    endsub;
run;

data lat_lng;
    set schools_sds(obs=10);
    call get_lat_long(full_address, &MAPQUEST_API_KEY, lat, long);
run;

proc print data=lat_lng;
    var full_address lat long;
run;


/*-----------------+
| Excel formatting |
+-----------------*/

proc fcmp;
    length libpath path outfile $ 500;
    libpath = pathname('work');
    path = catx('\',libpath,'schools_sds.sas7bdat');
    file log;

    declare object py(python);
    submit into py;
    def format_excel(datasetpath):
        """Output: output_file"""
        import pandas
        import pathlib
        import xlsxwriter

        # read a SAS dataset
        schools_df = pandas.read_sas(datasetpath, encoding='latin1')

        # output an Excel file
        file_path = pathlib.Path('XXXX\excel_output')
        file_name = 'example_excel_export.xlsx'
        sheet_name = 'Augmented CDE Data'

        # setup Excel file writer
        with pandas.ExcelWriter(
            pathlib.Path(file_path, file_name), engine='xlsxwriter'
        ) as writer:
            schools_df.to_excel(
                writer,
                sheet_name=sheet_name,
                index=False,
                startrow=1,
                header=False,
            )
            max_column_index = schools_df.shape[1] - 1

            # setup formatting to be applied below
            workbook = writer.book
            text_format = workbook.add_format({'num_format': '@'})
            header_format = workbook.add_format({
                'bold': True,
                'text_wrap': True,
                'valign': 'center',
                'num_format': '@',
                'fg_color': '#FFE552',  # Light Gold
                'border': 1,
            })

            # write header row values with formatting
            worksheet = writer.sheets[sheet_name]
            for col_num, value in enumerate(schools_df.columns.values):
                worksheet.write(0, col_num, value, header_format)

            # use fixed column width and use a universal text format
            worksheet.set_column(0, max_column_index, 20, text_format)
          
            # turn on filtering for top row
            worksheet.autofilter(
                0, 0, schools_df.shape[0], max_column_index
            )
         
            # turn on freeze panes for top row
            worksheet.freeze_panes(1, 0)
        return str(pathlib.Path(file_path, file_name))
    endsubmit;

    rc = py.publish();
    rc = py.call('format_excel', path);
    outfile = py.results['output_file'];
    put 'Output file: ' outfile;
run;


/*------------+
| Import YAML |
+------------*/

proc fcmp;
    length workpath outfile $ 500;
    workpath = pathname('work');
    file log;

    declare object py(python);
    submit into py;
        def import_yaml_to_sas(workpath):
            """Output: output_table"""
            import yaml
            import requests
            from pandas import json_normalize
            import sys
            setattr(sys.stdin, 'isatty', lambda: False)
            from saspy import SASsession
            
            url = 'https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml'
            request_response = requests.get(url)
            if request_response.status_code != 200:
                return ' '

            legislators_list = yaml.safe_load(request_response.text)
            legislators_df = json_normalize(legislators_list)
            legislator_info = legislators_df[[
                'id.cspan',
                'name.first',
                'name.middle',
                'name.last',
                'bio.birthday',
                'bio.gender'
            ]]
            
            sas = SASsession()
            sas.saslib(libref='out',path=workpath)
            outds = sas.dataframe2sasdata(
                df=sas.validvarname(legislator_info),
                libref='out',
                table='legislators',
                encode_errors='replace'
            )
            sas.endsas()
            return outds.table
    endsubmit;

    rc = py.publish();
    rc = py.call('import_yaml_to_sas', workpath);
    outfile = py.results['output_table'];
    if not missing(outfile) then
        put 'Output dataset:' outfile;
run;

proc print data=legislators(obs=10);
run;
