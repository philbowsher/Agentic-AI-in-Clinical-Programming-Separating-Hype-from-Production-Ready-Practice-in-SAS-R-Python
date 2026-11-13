/*******************************************************************
* Program:  adsl.sas
* Purpose:  Derive ADSL (Subject-Level Analysis Dataset)
* Study:    CDISCPILOT01
* Inputs:   data/sdtm/dm.xpt, data/sdtm/ex.xpt, data/sdtm/ds.xpt
* Output:   data/adam/adsl.sas7bdat
* Run from: the project folder (paths are relative to it)
* Note:     Example legacy program for the workshop.
*******************************************************************/

options validvarname=upcase;

/* Read the SDTM transport files delivered by data management */
%macro read_xpt(domain);
  libname x&domain xport "data/sdtm/&domain..xpt";
  data &domain;
    set x&domain..&domain;
  run;
  libname x&domain clear;
%mend read_xpt;

%read_xpt(dm)
%read_xpt(ex)
%read_xpt(ds)

libname adam "data/adam";

/* First and last exposure dates */
proc sort data=ex;
  by usubjid exstdtc;
  where exdose > 0 or (exdose = 0 and index(upcase(extrt), 'PLACEBO') > 0);
run;

data ex_first (keep=usubjid trtsdt) ex_last (keep=usubjid trtedt);
  set ex;
  by usubjid;
  format trtsdt trtedt date9.;
  if first.usubjid then do;
    trtsdt = input(substr(exstdtc, 1, 10), yymmdd10.);
    output ex_first;
  end;
  if last.usubjid then do;
    trtedt = input(substr(exendtc, 1, 10), yymmdd10.);
    output ex_last;
  end;
run;

/* End of study status */
data ds_eos (keep=usubjid eosstt);
  set ds;
  where dscat = 'DISPOSITION EVENT';
  length eosstt $20;
  if dsdecod = 'COMPLETED' then eosstt = 'COMPLETED';
  else eosstt = 'DISCONTINUED';
run;

proc sort data=dm;
  by usubjid;
run;

data adam.adsl;
  merge dm (in=a) ex_first ex_last ds_eos;
  by usubjid;
  if a;

  length trt01p trt01a $40 agegr1 $10 saffl ittfl $1;
  trt01p = arm;
  trt01a = actarm;

  if age <= 65 then agegr1 = '<65';
  else if 65 < age <= 80 then agegr1 = '65-80';
  else if age > 80 then agegr1 = '>80';

  ittfl = 'Y';
  if not missing(trtsdt) then saffl = 'Y';
  else saffl = 'N';

  if not missing(trtsdt) and not missing(trtedt) then trtdurd = trtedt - trtsdt + 1;
run;
