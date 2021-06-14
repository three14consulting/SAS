/******************************************************************************
 DESCRIPTION:
     Small program to demonstrate some of the basic features of SAS.
 
 Dataset:
     "Billionaires"
     https://corgis-edu.github.io/corgis/csv/billionaires/
     Data does have errors but the purpose of this program is not to clean
     but to demonstrate basic features of SAS.
     
 SAS Features Used:
     * Macro variables
     * Rerouting the log to a file using PROC PRINTTO
     * Assigning library using the LIBNAME statement
     * Using the ODS to reroute the output to a pdf file
     * Importing data via the FILENAME statement
     * PROC PRINT
     * PROC DATASETS
     * PROC FREQ
     * PROC SORT
     * Make custom Format using the dataset PROC FORMAT
     * BY-Group processing: using FIRST. and LAST. variables
     * Match-Merge Processing
     * DO Loops
     * PROC SUMMARY
     * PROC TRANSPOSE
     * PROC EXPORT
     
******************************************************************************/
%let root = /folders/myfolders/Portfolio;
%let prjct = SAS_01_Base_Programming;
%let dir = &root/&prjct;

/* Print log to file */
proc printto log="&dir/logs/Log_&prjct..txt";
run;

libname sasout "&dir/sasdata/";

/* Print output to PDF */
ods pdf style = HTMLEncore;
ods pdf file = "&dir/ods/ODS_&prjct..pdf" contents=yes;

/* Import data */
filename billref "&dir/data/billionaires.csv";
data billionaires (drop = wealth_how_from_emerging wealth_was_founded 
                          wealth_was_political);
length name $45.  company_name $59.
       company_relationship $46.  company_sector $52.
       company_type $22.  gender $14.
       location $20.  location_code $6.
       region $24.  wealth_type $24.
       wealth_how $18.  wealth_how_from_emerging $4.
       wealth_how_industry $31.  wealth_inherited $24.  
       wealth_was_founded $4.  wealth_was_political $4.;
infile billref
	delimiter = ','
	missover
	dsd
	firstobs = 2;
informat location_gdp e14.;
input name $  rank
     year  company_founded
     company_name $  company_relationship $
     company_sector $  company_type $
     age  gender $  location $
     location_code $  location_gdp
     region $  wealth_type $
     wealth_bn  wealth_how $
     wealth_how_from_emerging $  wealth_how_industry $
     wealth_inherited $  wealth_was_founded $
     wealth_was_political $ ;
format location_gdp comma20.;
run;

/* Create a copy of the file */
data sasout.billionaires;
set billionaires;
run;

Title 'Sample of Billionaires Dataset';
proc print data = billionaires (obs=10);
run;

Title 'Properties of Billionaries Dataset';
proc datasets ;
 contents data = billionaires ;
run;


/* Frequencies of Character Variables */
Title 'Frequencies of Character Variables';
proc freq data = billionaires(drop = name company_sector
                                     company_name) order = freq;
    tables _character_;
run;


/* Make Format from Dataset */
proc sort data = billionaires 
out = format_tmp(keep = location_code location);
    by location_code location;
run;
proc sort data = format_tmp nodupkey;
    by location_code;
run;
data format_data;
   set format_tmp(rename=(location_code=start
                            location=label))
                            end=last;
   retain fmtname '$country_fmt' ;
run;
proc format library=work cntlin=format_data;
run;


/* Compile a dataset of Billionaires that appear more than once */
proc sort data = billionaires;
   by name year;
run;
data multiple_appearances (keep = name appearances 
                                  year_entered most_recent_year
                                  wealth_entered most_recent_wealth
                                  wealth_chg);
    format wealth_entered most_recent_wealth wealth_chg 4.1;
    set billionaires;
    retain year_entered wealth_entered;
    by name;
    if first.name then do;
	    appearances = 0;
	    year_entered = year;
	    wealth_entered = wealth_bn;
    end;
    appearances + 1;
    if last.name and appearances > 1 then do ;
        most_recent_year = year;
        most_recent_wealth = wealth_bn;
        wealth_chg = most_recent_wealth - wealth_entered;
        output;
    end;
proc sort;
    by name;
run;
/* Highest Rank */
proc sort data = billionaires;
    by name rank;
run;
data ranks(keep = name highest_rank lowest_rank
                  highest_rank_year lowest_rank_year);
    retain name highest_rank lowest_rank 
           highest_rank_year lowest_rank_year;
    set billionaires;
    retain highest_rank highest_rank_year;
    by name;
    if first.name then do;
        highest_rank = rank;
        highest_rank_year = year;
    end;
    if last.name then do;
        lowest_rank = rank;
        lowest_rank_year = year;
        output;
    end;
proc sort;
    by name;
run;
/* Merge two preceding datasets */
data sasout.app_with_ranks(drop=i);
    retain name appearances
           highest_rank lowest_rank 
           highest_rank_year lowest_rank_year
           year_entered most_recent_year wealth_entered
           most_recent_wealth wealth_chg;
    format estimated_wealth 5.1;
    merge multiple_appearances (in=a)
          ranks (in=b);
    by name;
    /* Estimate wealth in 2024, Assumed 5% growth*/
    estimated_wealth = most_recent_wealth;
    do i=1 to 10;
         estimated_wealth + estimated_wealth * 0.05;
    end; 
    if a and b then output;
proc sort;
    by descending appearances highest_rank name;
run;


/* Number of Billionaires by Country by Year in Wide format */
proc summary data = billionaires nway missing;
    var year;
    class location year;
    output out = long_format(drop=_:) n=billionaires;
proc sort;
   by location year;
run;
proc transpose data = long_format out = country_time_series(drop=_name_);
    by location;
    var billionaires;
    id year;
run;
data sasout.country_time_series(rename=(location = country));
    retain location _1996 _2001 _2014;
    set country_time_series;
    array change _numeric_;
        do over change;
            if change=. then change=0;
        end;
run;


/* Export analysis to an XSLX workbook that can be distributed */
proc export data = sasout.app_with_ranks
    outfile = "&dir/output/Excel_&prjct..xlsx"
    dbms = xlsx
    replace;
    sheet = appearances;
run;
proc export data = sasout.country_time_series
    outfile = "&dir/output/Excel_&prjct..xlsx"
    dbms = xlsx
    replace;
    sheet = ctry_series;
run;


/* Reset log location */
proc printto log = log;
run;

/* Close ODS */
ods pdf close;