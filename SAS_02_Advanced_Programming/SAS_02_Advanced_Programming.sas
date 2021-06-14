/******************************************************************************
 DESCRIPTION:
     Program demonstrating more advanced programming features of SAS.
 
 Dataset:

     
 SAS Features Used:
     * System options relating to Macro processing:
         - SYMBOLGEN
         - MPRINT
         - MLOGIC
     * PROC SQL:
         - Accessing dictionary tables
         - SELECT INTO
       To see more use of PROC SQL, please see program located in SQL
       directory.
     * SAS Macros
     * Array Processing
     * Hash Tables
     * PROC FCMP: SAS Function Compiler
     * Regular Expressions
     
******************************************************************************/
options symbolgen mprint mlogic;
%let root = /folders/myfolders/Portfolio;
%let prjct = SAS_02_Advanced_Programming;
%let dir = &root/&prjct;

/* Print log to file */
/* proc printto log="&dir/logs/Log_&prjct..txt"; */
/* run; */

libname sasout "&dir/sasdata/";

/* Print output to PDF */
ods pdf style = HTMLEncore;
ods pdf file = "&dir/ods/ODS_&prjct..pdf" contents=yes;

/*  How many datasets are in sashelp? */
proc sql noprint;
    select count(*) into: dataset_ct
    from dictionary.tables
    where memtype='DATA'
    and libname='SASHELP';
quit;
%put &dataset_ct Datasets in SASHELP;
    

/* Using PROC SQL and PROC PRINT, print report of team members for each team in */
/* sashelp.baseball */
data sasout.baseball;
    set sashelp.baseball;
run;
proc sql noprint;
    select distinct
        team into: team1-
    from sasout.baseball;
quit;
%put _user_;

%macro print_report(dataset=dataset, variab=variab);
    %do i = 1 %to &sqlobs;
	    proc sort data = &dataset(where=(team=%str("&&team&i")))
	    out = sorteddataset;
	        by &variab;
	    run;
		Title "Roster of &&team&i";
        proc print data = sorteddataset;
            var &variab;
        run;
        proc datasets nodetails nolist;
            delete sorteddataset;
        run;
    %end;
%mend print_report;

%print_report(dataset=sasout.baseball, variab=name position);


/* Using SASHELP.PRICEDATA and Array Processing, increase the price */
/* the latest prices by 10% */
data sasout.pricedata;
    set sashelp.pricedata;
run;
data pricedata(keep = price1-price17);
    set sasout.pricedata end=last;
    array p[*] price1-price17;
    do i=1 to dim(p);
        p[i] = p[i] * 1.10;
    end;
    if last then output;
run;


/* Using the billionaires dataset from SAS_01_Base_Programming Project */
/* and with a Hash Table, return rows from the dataset that are in */
/* the Scandinavian countries */
libname sasin "&root/SAS_01_Base_Programming/sasdata" access=readonly;
data sasout.scandinavian_billionaires(drop=code test);
drop rc;
length code $3 test $4;
    if _n_ = 1 then do;
        call missing(code, test);
        declare hash h();
        h.definekey('code');
        h.definedata('test');
        h.definedone();
        h.add(key:'NOR', data:'test');
        h.add(key:'FIN', data:'test');
        h.add(key:'SWE', data:'test');
        h.add(key:'ISL', data:'test');
    end;
    set sasin.billionaires(where=(length(location_code)<=3));
    rc = h.find(key:location_code);
    if rc = 0 then output;
run;

/* Close ODS */
ods pdf close;