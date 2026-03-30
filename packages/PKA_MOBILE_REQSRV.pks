create or replace PACKAGE BODY       "PKA_MOBILE_REQSRV" AS
--------------------------------------------------------------------------------
--คำนวณสิทธิกู้
--------------------------------------------------------------------------------
function fp_calc_loanpermit(as_message varchar2)return varchar2   AS                            
 
 
ls_loantype sc_lon_m_rule.loan_type%type  ;
ls_memloan sc_mem_m_membership_registered.membership_no%type ;
ldc_salary NUMBER(15,2) := 0 ;
ldc_expense NUMBER(15,2) := 0 ;
ldc_income NUMBER(15,2) := 0 ;
ls_mobile_mode char := 'M' ;
--ls_paytype sc_lon_m_rule.loan_payment_type_code%type := null  ;
ldc_academic NUMBER(15,2) := 0 ;
ldc_back_pay NUMBER(15,2) := 0 ;
ldc_coop NUMBER(15,2) := 0 ;
ldc_net NUMBER(15,2) := 0 ;
ldc_permit NUMBER(15,2) := 0 ;
ldc_salary_total NUMBER(15,2) := 0 ;
ldc_salary_net NUMBER(15,2) := 0 ;
ldc_ot_1 NUMBER(15,2) := 0 ;
ldc_ot_2 NUMBER(15,2) := 0 ;
ldc_ot_3 NUMBER(15,2) := 0 ;
ls_mode varchar2(2); 

                        
ls_arg varchar2(4000)  := '' ;
li_maxinstall  pls_integer;
li_max_rule pls_integer;
--li_install pls_integer;


ldc_payment NUMBER(15,2) := 0 ;
ldc_payment_install NUMBER(15,2) := 0 ;
ldc_provident_fund NUMBER(15,2) := 0 ;
ldc_over_percen NUMBER(15,2) := 0 ; 
ldc_save_percen NUMBER(15,2) := 0 ;
ldc_average_over NUMBER(15,2) := 0 ; 
ldc_average_save NUMBER(15,2) := 0 ;
ldc_overtime_cur1 NUMBER(15,2) := 0 ;
ldc_overtime_cur2 NUMBER(15,2) := 0 ;
ldc_average_ot NUMBER(15,2) := 0 ;
ldc_average_ot70 NUMBER(15,2) := 0 ;
ldc_average_ot20 NUMBER(15,2) := 0 ;
ldc_average_ot80 NUMBER(15,2) := 0 ;
ldc_salary_total30 NUMBER(15,2) := 0 ;
ldc_salarynet_minus NUMBER(15,2) := 0 ;
ldc_ot_net70 NUMBER(15,2) := 0 ;
ldc_ot_after_save NUMBER(15,2) := 0 ;
ldc_ot_after_total NUMBER(15,2) := 0 ;
ldc_sum_amount NUMBER(15,2) := 0 ;
ldc_income_total NUMBER(15,2) := 0 ;
ldc_etimated_balance NUMBER(15,2) := 0 ;
ls_keyvalue   varchar2(4000);

LDC_USED_AMOUNT_NOT SC_LON_M_CONTRACT_COLL.USED_AMOUNT%type;

--------------------------------------------------------------------------------
ldt_startkeep date ;
ls_paytype sc_lon_m_rule.loan_payment_type_code%type; 
li_install sc_lon_m_rule.maximum_loan_installment%type := 1 ;
ldc_payment_last number := 0;


ldc_share_stock sc_mem_m_share_mem.SHARE_STOCK%type;
ldc_sharestock_bal sc_mem_m_share_mem.SHARE_STOCK%type;
LDC_USED_OTHER SC_LON_M_CONTRACT_COLL.USED_AMOUNT%type;
ldc_permit_calcu NUMBER(15,2) := 0 ;
ldc_coll_dep NUMBER(15,2) := 0 ;

li_install_by_age    NUMBER := 0;
LDT_DATE_OF_BIRTH sc_mem_m_membership_registered.DATE_OF_BIRTH%type;
ld_today             DATE := TRUNC(SYSDATE);
ldc_principal_balance  SC_LON_M_LOAN_CARD.PRINCIPAL_BALANCE%type;
ldc_calint NUMBER := 0;
--------------------------------------------------------------------------------




BEGIN
  select replace ( as_message , '"' , '' ) into ls_keyvalue
  from dual ;
  ls_keyvalue := substr( trim(ls_keyvalue) , 2 , len( trim(ls_keyvalue) ) - 1 );
  select upper ( ls_keyvalue) into ls_keyvalue
  from dual ;  
  
  ls_loantype  := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'LOAN_TYPE'));
  ls_memloan := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'MEMBER_CODE'));
  ldc_salary  := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'SALARY'));
  ldc_expense   := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'EXPENSE'));
  ldc_income    := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'INCOME'));
  ls_mobile_mode := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'TYPE'));
  ls_paytype := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'PAYTYPE'));
  ldc_academic := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'ACADEMIC'));
  ldc_back_pay := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'BACKPAY'));
  ldc_coop := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'COOP'));
  ldc_net := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'NET'));
  ldc_permit := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'PERMIT'));
  ldc_salary_total := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'SALARYTOTAL'));
  ldc_salary_net := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'SALARYNET'));
  ldc_ot_1 := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'OT1'));
  ldc_ot_2 := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'OT2'));
  ldc_ot_3 := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'OT3'));
  ls_mode := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'MODE')); 
  ldc_coll_dep := TRIM(pka_mobile.fp_KeyValueGet(ls_keyvalue,'COLL_DEP'));


if ls_mode = '01' then -- ถ้า 01 ให้เป็นการคำนวณ หา รายได้ที่จะสามารถกู้ได้    ถ้าเป็นการคำนวณสิทธิกู้ หรือขอกู้ ปกติ ให้ตก else ไปเลย แล้วเอา Script มาติดตั้งเอา
  
  
  
  
if ls_loantype in ('60') then

-------ตรวจสอบ
  begin
  SELECT NVL(sum(PRINCIPAL_BALANCE), 0)
  INTO   ldc_principal_balance
  FROM   SC_LON_M_LOAN_CARD
  WHERE  LOAN_TYPE = '60'
  AND  MEMBERSHIP_NO = ls_memloan
  AND  PRINCIPAL_BALANCE > 0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ldc_principal_balance := 0;
    
        WHEN OTHERS THEN
            ldc_principal_balance := 0;
    END;
  
  if ldc_principal_balance <> 0 then
    if ldc_permit < ldc_principal_balance  then
      ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message', 'ท่านมีหนี้เก่าต้องหักกลบจำนวน '||to_char(ldc_principal_balance, '999,999,990.99')|| ' ยอดกู้ไม่เพียงพอ' ) ;
      ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message_status', '0' ) ;
      Goto END_SP;
    end if ;
    
    
  end if ;



  begin
      select loan_payment_type_code ,maximum_loan_installment
      into ls_paytype , li_maxinstall
      from sc_lon_m_rule 
      where loan_type = ls_loantype ;
  exception
  when too_many_rows then spa_dberror('E109:too_many_rows') ;
  when no_data_found then spa_dberror('E110:no_data_found');
  when others then spa_dberror('E111:fp_calc_loanpermit');
  end ;


--  ldt_startkeep := pka_lon_reqsrv.fp_rule_startkeep(ls_loantype,ls_memloan,to_date( sysdate ,'dd/mm/yyyy' ) ) ;
--  PKA_LON_REQSRV.sp_calc_install(ls_memloan, ls_loantype ,to_date( sysdate ,'dd/mm/yyyy' ), ls_paytype ,'P'  ,ldc_permit ,li_install ,ldc_payment , ldt_startkeep ,'0') ;
--  li_install := PKA_LON_REQSRV.fp_calc_install_value('1') ;
--  ldc_payment := PKA_LON_REQSRV.fp_calc_install_value('2') ;
--  ldc_payment_last := PKA_LON_REQSRV.fp_calc_install_value('3') ;
    
-----หุ้นค้ำประกันประเภทอื่น    
  BEGIN
      SELECT NVL(SUM(SC_LON_M_CONTRACT_COLL.USED_AMOUNT), 0)
      INTO   LDC_USED_OTHER
      FROM   sc_lon_m_contract_coll,
             sc_lon_m_loan_card,
             sc_lon_m_rule
      WHERE  SC_LON_M_CONTRACT_COLL.LOAN_CONTRACT_NO = sc_lon_m_loan_card.LOAN_CONTRACT_NO
        AND  sc_lon_m_loan_card.loan_type = sc_lon_m_rule.loan_type
        AND  sc_lon_m_contract_coll.REF_OWN_NO = ls_memloan
        AND  sc_lon_m_contract_coll.COLLATERAL_TYPE_CODE = '02'
        AND  sc_lon_m_loan_card.loan_type <> '60'
        AND  SC_LON_M_LOAN_CARD.PRINCIPAL_BALANCE > 0;
  
  EXCEPTION
      WHEN OTHERS THEN
          LDC_USED_OTHER := 0;
  END;

------ทุนเรือนหุ้น
  BEGIN
      SELECT NVL(SHARE_STOCK, 0)
      INTO   ldc_share_stock
      FROM   sc_mem_m_share_mem
      WHERE  MEMBERSHIP_NO = ls_memloan;
  
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
          ldc_share_stock := 0;
  
      WHEN OTHERS THEN
          ldc_share_stock := 0;
  END;
  

  if ldc_permit > LDC_SHARE_STOCK then
      ldc_sharestock_bal := 0;
  else
      ldc_sharestock_bal := LDC_SHARE_STOCK - (LDC_USED_OTHER + (CEIL((ldc_permit*100/90) / 10) * 10));
      if ldc_sharestock_bal < 0 then
          ldc_sharestock_bal := 0;
      end if;
  end if;
 

  ldc_permit_calcu := ((LDC_SHARE_STOCK - LDC_USED_OTHER) + ldc_coll_dep) * 0.9;
  
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'sharestock_bal', trim(to_char(ldc_sharestock_bal, '999999990.99')));
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'permitcalcu', trim(to_char(ldc_permit_calcu, '999999990.99')));
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'share_stock', trim(to_char(ldc_share_stock, '999999990.99')));

  -- 1. ดึงวันเกิด
  SELECT DATE_OF_BIRTH
  INTO   LDT_DATE_OF_BIRTH
  FROM   sc_mem_m_membership_registered
  WHERE  membership_no = ls_memloan;

  
  -- 2. คำนวณอายุ (ปี)
--  li_install_by_age := FLOOR(MONTHS_BETWEEN(ADD_MONTHS(LDT_DATE_OF_BIRTH, 70*12), ld_today));
  li_install_by_age := 1000; --จะให้นับอายุถึง 70 ุ็เปิดบรรทัดบน
  -- 3. เลือกค่าน้อยสุด
  li_maxinstall := LEAST(li_maxinstall, li_install_by_age);
  -- กันค่าติดลบ
  IF li_maxinstall < 0 THEN
    li_maxinstall := 0;
  END IF;
  
  --ชำระต่องวด 
  ldt_startkeep := pka_lon_reqsrv.fp_rule_startkeep(ls_loantype,ls_memloan,to_date( sysdate ,'dd/mm/yyyy' ) ) ;
  PKA_LON_REQSRV.sp_calc_install(ls_memloan, ls_loantype ,to_date( sysdate ,'dd/mm/yyyy' ), ls_paytype ,'P'  ,ldc_permit ,li_maxinstall ,ldc_payment , ldt_startkeep ,'0') ;
  ldc_payment := PKA_LON_REQSRV.fp_calc_install_value('2') ;

  --งวด
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'install', trim( to_char( li_maxinstall ,'999999990.99' ))  ) ;
  --ยอดกู้
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'permit', trim( to_char( ldc_permit ,'999999990.99' ))  ) ;
  --ชำระต่องวด
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'payment', trim( to_char( ldc_payment ,'999999990.99' ))  ) ;
  
   if ldc_permit_calcu >= ldc_permit then
    ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message', 'กู้ได้ตามเกณฑ์' ) ;
    ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message_status', '1' ) ;
  else
    ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message', 'ไม่สามารถกู้ได้ตามเกณฑ์' ) ;
    ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message_status', '0' ) ;
  end if ; 
  

  Goto END_SP;
end if;  
  
  
  
  li_maxinstall := pka_lon_reqsrv.fp_calc_install_max(ls_memloan ,ls_loantype ,to_date( sysdate ,'dd/mm/yyyy' ) ,ldc_permit ,to_date( sysdate ,'dd/mm/yyyy' ));
  li_max_rule := pka_lon_reqsrv.fp_calc_install_max_retire(ls_memloan,ls_loantype,to_date( sysdate ,'dd/mm/yyyy' ) )-1;

  if li_max_rule > li_maxinstall then
    li_install := li_maxinstall;
  else
    li_install := li_max_rule;
  end if;

  --ชำระต่องวด
  ldc_payment := ldc_permit / li_install ;

  --งวด
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'install', trim( to_char( li_install ,'999999990.99' ))  ) ;
  --ยอดกู้
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'permit', trim( to_char( ldc_permit ,'999999990.99' ))  ) ;
  --ชำระต่องวด
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'payment', trim( to_char( ldc_payment ,'999999990.99' ))  ) ;

 ----ค่างวดเงินกู้
  begin
    select sum(sc_lon_m_contract.PERIOD_PAYMENT_AMOUNT)
    into ldc_payment_install
    from sc_lon_m_contract , 
    sc_lon_m_loan_card 
    where sc_lon_m_contract.LOAN_CONTRACT_NO = sc_lon_m_loan_card.LOAN_CONTRACT_NO
    and sc_lon_m_contract.membership_no = ls_memloan
    and sc_lon_m_contract.loan_type = ls_loantype
    and sc_lon_m_loan_card.PRINCIPAL_BALANCE > 0 ;
    exception
    when no_data_found  then 
    begin
      ldc_payment_install := 0;
    end ;
    when others then 
    begin
      ldc_payment_install := 0;
    end ;
  end ;
  if ldc_payment_install is null then 
    ldc_payment_install := 0 ;
  end if ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'payment_install', trim( to_char( ldc_payment_install ,'999999990.99' ))  ) ;
       
--  --กองทุนสำรองเลี้ยงชีพ คิดจากเงินเดือน
--  ldc_provident_fund := ldc_salary * 0.07 ;
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'provident_fund', trim( to_char( ldc_provident_fund ,'999999990.99' ))  ) ;
  
  --เปอร์เซนต์ค่าล่วงเวลา และค่ากันเงินได้
  begin
    select overtime_percen , savemoney_percen , average_overtime , average_savemoney
    into ldc_over_percen , ldc_save_percen ,ldc_average_over , ldc_average_save
    from sc_lon_m_rule
    where loan_type = ls_loantype ;
  exception
  when too_many_rows then spa_dberror('E001:too_many_rows') ;
  when no_data_found then spa_dberror('E002:no_data_found');
  when others then spa_dberror('E111:fp_calc_loanpermit');
  end ;
  
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'overtime_percen', trim( to_char( ldc_over_percen ,'999999990.99' ))  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'savemoney_percen', trim( to_char( ldc_save_percen ,'999999990.99' ))  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'average_overtime', trim( to_char( ldc_average_over ,'999999990.99' ))  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'average_savemoney', trim( to_char( ldc_average_save ,'999999990.99' ))  ) ;
  
  --OT ย้อน 3 เดือน
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'ot_1', trim( to_char( ldc_ot_1 ,'999999990.99' ))  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'ot_2', trim( to_char( ldc_ot_2 ,'999999990.99' ))  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'ot_3', trim( to_char( ldc_ot_3 ,'999999990.99' ))  ) ;
  
  --หาเป็นปัจจุบัน 70%
  ldc_overtime_cur1 := ldc_ot_1 * ldc_average_over ;
  --หาเป็นปัจจุบัน 30%
  ldc_overtime_cur2 := ldc_ot_1 * ldc_save_percen ;
  
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'overtime_cur1', trim( to_char( ldc_overtime_cur1 ,'999999990.99' ))  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'overtime_cur2', trim( to_char( ldc_overtime_cur2 ,'999999990.99' ))  ) ;
  
  --OT เฉลี่ย
  ldc_average_ot := (ldc_ot_1 + ldc_ot_2 + ldc_ot_3) / 3 ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'average_ot', trim( to_char( ldc_average_ot ,'999999990.99' ))  ) ;
  
  --OT เฉลี่ย 70%
  ldc_average_ot70 := ldc_average_ot * ldc_average_over;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'average_ot70', trim( to_char( ldc_average_ot70 ,'999999990.99' ))  ) ;
  
  --OT เฉลี่ย 3 ด. 	20%	 (ตามOT% หลังกันเงินได้) 	
  ldc_average_ot20 := ldc_average_ot * ldc_average_over * ldc_over_percen;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'average_ot20', trim( to_char( ldc_average_ot20 ,'999999990.99' ))  ) ;
  
  --OT เฉลี่ย 3 ด. 	80%	 (ตามOT% หลังกันเงินได้) 	
  ldc_average_ot80 := ldc_average_ot * 0.8 *  ldc_average_over ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'average_ot80', trim( to_char( ldc_average_ot80 ,'999999990.99' ))  ) ;
  
  --เงินเดือน		เงินได้รวม	30%
  ldc_salary_total30 := ldc_salary_total * ldc_save_percen ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'salary_total30', trim( to_char( ldc_salary_total30 ,'999999990.99' ))  ) ;
  
  --รวม	กันเงินได้	30% รายได้สุดธิ ลบ 30% ของรายได้รวม
  ldc_salarynet_minus :=   ldc_salary_net - ldc_salary_total30 ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'salarynet_minus', trim( to_char( ldc_salarynet_minus ,'999999990.99' ))  ) ;
  
  --หัก OT ปัจจุบัน	พ.ย.68	70%
  ldc_ot_net70 := ldc_salarynet_minus - ldc_overtime_cur1 ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'ot_net70', trim( to_char( ldc_ot_net70 ,'999999990.99' ))  ) ;
  
  --บวก OT เฉลี่ย 3 ด. 	20%	 (ตามOT% หลังกันเงินได้) 	
  if ldc_average_ot20 > ldc_overtime_cur1 then
    ldc_ot_after_save := ldc_overtime_cur1 ;
  else
    ldc_ot_after_save := ldc_average_ot20 ;
  end if ;
  ldc_ot_after_total := ldc_ot_net70 + ldc_ot_after_save ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'ot_after_total', trim( to_char( ldc_ot_after_total ,'999999990.99' ))  ) ;
  
  
  --ldc_ot_after_total + ค่างวดเงินกู้สัญญา 11	+ ลดกองทุนสำรองเลี้ยงชีพ	
  ldc_sum_amount := ldc_ot_after_total + ldc_payment_install + ldc_provident_fund ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'sum_amount', trim( to_char( ldc_sum_amount ,'999999990.99' ))  ) ;
  
  --เงินได้คงเหลือตามเกณฑ์	
  ldc_income_total := ldc_sum_amount - ldc_payment ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'income_total', trim( to_char( ldc_income_total ,'999999990.99' ))  ) ;
  
  --มีเงินได้คงเหลือต่อเดือนประมาณ		
  ldc_etimated_balance := ldc_income_total + ldc_salary_total30 + ldc_average_ot80 ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'etimated_balance', trim( to_char( ldc_etimated_balance ,'999999990.99' ))  ) ;

  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'member_code', trim( ls_memloan )  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'type', trim( ls_mobile_mode )  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'loan_type', trim( ls_loantype )  ) ;


  if ldc_income_total < 1000 then
    ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message', 'เงินได้คงเหลือตามเกณฑ์ ไม่เพียงพอ ไม่สามารถกู้ได้' ) ;
    ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message_status', '0' ) ;
  else
    ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message', 'เงินได้คงเหลือตามเกณฑ์ เพียงพอ สามารถกู้ได้' ) ;
    ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message_status', '1' ) ;
  end if ; 

else

NULL ; --ถ้าเป็นการคำนวณสอทธิกู้ หรือ ขอกู้แบบ ปกติ ก็เอา Script มาติดตั้งเอาใน else


end if ;
  <<END_SP>>null; 
  ls_arg := '{'||ls_arg||'}' ; 
  return ls_arg  ;


END fp_calc_loanpermit;

--------------------------------------------------------------------------------
--เปลี่ยนแปลงการส่งหุ้น
--------------------------------------------------------------------------------
--function fp_validate_change_share(as_memno varchar2,as_dropstatus char default '2' 
--                                 ,adc_sharemonthly number,adt_opdate date
--                                 ,as_mobile_mode char default 'M') return varchar2   AS
--ls_arg varchar2(4000);
----Type V5 <> wepApp 
--ls_memno sc_mem_m_membership_registered.membership_no%type := as_memno ;
--ls_response_code sc_mobile_recv_msg.response_code%type := '<>';
--ls_chgshare sc_cnt_m_coop.mobile_chgshare_can%type ;
--begin
--  is_mobile_mode := 'M' ; --กำหนดมาจาก Mobile
--  ls_arg := '';
--
--  select mobile_chgshare_can into ls_chgshare 
--  from sc_cnt_m_coop  ;
--  if ls_chgshare = '0' then
--
--      ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'errorkey', 'timeout');  
--      ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'errormessage', 'หมดเวลายื่นคำขอเปลี่ยนแปลง');    
--      ls_arg := '{'||ls_arg ||'}' ;
--  else
--
--      pka_mem_ctl.is_mobile_message := ''  ;
--      pka_mem_ctl.sp_validate_change_share(ls_memno ,as_dropstatus ,adc_sharemonthly ,adt_opdate  ) ;
--      ls_arg := pka_mem_ctl.is_mobile_message ;
--
--      if ls_arg is null or len( trim( ls_arg))  = 0 then  
--          ls_arg := '';  
--          ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'code', 'CWL200SUCCESS');  
--          ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'message', 'บันทึกการเปลี่ยนแปลงค่าหุ้นสำเร็จ');
--          ls_arg := '{'||ls_arg ||'}' ;
--          ls_response_code := 'SUCCESS' ;
--      end if ;
--  end if ;  
--
--  INSERT INTO sc_mobile_recv_msg  
--       (  operate_time,              
--          bank_code,                 confirm_status,   
--          method_uri,                membership_no,           
--          trans_amount,              trans_fee,             
--          return_msg,                response_code )
--   select to_char( systimestamp,'YYYY-MM-DD HH24:MI:SS.FF3'),              
--          '000',                       '0',   
--          'CHANGESHARE',              membership_no,           
--          adc_sharemonthly,           share_amount,             
--          ls_arg,                     ls_response_code
--
--   from sc_mem_m_share_mem
--   where membership_no = ls_memno
--   ;
--
--  return ls_arg ;
--
--end fp_validate_change_share;
--------------------------------------------------------------------------------
--ดอกเบี้ยชำระพิเศษ
--------------------------------------------------------------------------------
function fp_calint( as_conno varchar2  ) return varchar2  as 
ls_arg varchar2(4000) := ' ';
ldc_prinamount number ; --อาจบังคับให้ชำระไม่เกิน ยอดคงเหลือ - ยอดรอเรียกเก็บก้อได้ พี่เลยไม่อยากใช้ ตัวแปร ชื่อ principal_balance เดี๋ยวจะเข้าใจกันผิด
ldc_intamount number ;
ldc_balance number ;
ldc_pending number ;
ldc_calint number ;
ldc_intarr number ;
ldc_old_intarr number ;
--Type V5 <> wepApp 
ls_conno sc_lon_m_loan_card.loan_contract_no%type := as_conno ;

begin
  select PRINCIPAL_BALANCE , decode( keeping_status , '1' , pending_amount , 0 ) 
  , pka_lon_intsrv.fp_calint(loan_contract_no, to_date( sysdate ,'dd/mm/yyyy' ) ,PRINCIPAL_BALANCE)
  , interest_arrear 
  , old_interest_arrear
  into  ldc_balance , ldc_pending
        ,ldc_calint , ldc_intarr , ldc_old_intarr
  from sc_lon_m_loan_card
  where loan_contract_no = ls_conno ;

  --มาจัดการยอดที่ต้องการให้ชำระ กันตรงนี้เอาเอง
  ldc_prinamount := ldc_balance ; 
  ldc_intamount := ldc_calint + ldc_intarr + ldc_old_intarr ;

  ls_arg := '';  
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'principal_amount', trim( to_char( ldc_prinamount ,'999999990.99' ))  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'interest_amount', trim( to_char( ldc_intamount ,'999999990.99' ))  ) ;
  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'item_amount', trim( to_char( ldc_prinamount + ldc_intamount ,'999999990.99' ))  ) ;


  if ls_arg is null then ls_arg := ' ' ; end if ;
  return ls_arg ;

end fp_calint ;
--------------------------------------------------------------------------------
--ข้อมูลเงินกู้ที่อยากได้ เงินต้นที่ชำระได้ ดอกเบี้ยที่ต้องได้รับชำระ  ดอกค้าง  ดอกค้างเก่า
--------------------------------------------------------------------------------
function fp_get_loan_info(as_conno varchar2 , as_column varchar2 )  return number  as
ldc_prinamount number ; --อาจบังคับให้ชำระไม่เกิน ยอดคงเหลือ - ยอดรอเรียกเก็บก้อได้ พี่เลยไม่อยากใช้ ตัวแปร ชื่อ principal_balance เดี๋ยวจะเข้าใจกันผิด
ldc_intamount number ;
ldc_balance number ;
ldc_pending number ;
ldc_calint number ;
ldc_intarr number ;
ldc_old_intarr number ; 
--Type V5 <> wepApp 
ls_conno sc_lon_m_loan_card.loan_contract_no%type := as_conno ;

begin
  select PRINCIPAL_BALANCE , decode( keeping_status , '1' , pending_amount , 0 ) 
  , pka_lon_intsrv.fp_calint(loan_contract_no, to_date( sysdate ,'dd/mm/yyyy' ) ,PRINCIPAL_BALANCE)
  , interest_arrear 
  , old_interest_arrear
  into  ldc_balance , ldc_pending
        ,ldc_calint , ldc_intarr , ldc_old_intarr
  from sc_lon_m_loan_card
  where loan_contract_no = ls_conno ;

  --มาจัดการยอดที่ต้องการให้ชำระ กันตรงนี้เอาเอง
  ldc_prinamount := ldc_balance ; 
  ldc_intamount := ldc_calint + ldc_intarr + ldc_old_intarr ;


  case lower( as_column )
  when 'prinamount' then
    return ldc_prinamount ;  
  when 'intamount' then
    return ldc_calint + ldc_intarr + ldc_old_intarr ;    
  when 'principal_balance' then
    return ldc_balance ;
  when 'pending_amount' then
    return ldc_pending ;   
  when 'interest_arrear' then
    return ldc_intarr  ;  
  when 'old_interest_arrear' then
    return ldc_old_intarr ;      
  end case ;

  return 0 ;

end fp_get_loan_info ;
--------------------------------------------------------------------------------
--คำนวณงวดผ่อน
--------------------------------------------------------------------------------
--function fp_calc_install( as_memloan varchar2 , as_loantype varchar2 
--    , as_paytype varchar2 ,as_caltype char default 'P' ,adc_permit number ,ai_install pls_integer
--    , adc_payment number   ) return varchar2  as
--
--ls_arg varchar2(4000);    
--ldc_payment number := 0;
--ldc_payment_last number := 0;
--li_install sc_lon_m_rule.maximum_loan_installment%type := 1 ;
--ldt_startkeep date ;
--ldc_print_bal NUMBER(15,2);
--ldc_int_res NUMBER(15,2);
--ldc_buy_share number ;
--ldc_real_amount number := 0;
--ldc_interest_first number(38,2);
--ldt_start_date date;
--ldt_next_month date;
--ldt_int_rate NUMBER(10,6);
--
---- BENZ 10/10/2568
--li_maxinstall  pls_integer;
--begin
----Niorn 2023-12-15 TGE แก้จำนวนเงิน คำนวณงวดไม่ให้เกินงวด กษ
----  if ai_install = 0 then  
----    if adc_payment = 0 then
----        select maximum_loan_installment into li_install
----        from sc_lon_m_rule
----        where loan_type = as_loantype ;
----    end if ;    
----  else
----    li_install  :=   ai_install ;
----  end if ;
--
--    if ai_install = 0 then
--       li_install := pka_lon_reqsrv.fp_calc_install_max(as_memloan ,as_loantype ,to_date( sysdate ,'dd/mm/yyyy' ) ,adc_permit ,to_date( sysdate ,'dd/mm/yyyy' ));
--   else
--      li_install  :=   ai_install ;
--   end if ;
--   
--  ldc_payment := adc_payment ;
--  --Niorn 2023-05-18 TGE เริ่มชำระเดือนถัดไป
----  PKA_LON_REQSRV.sp_calc_install(as_memloan, as_loantype ,to_date( sysdate ,'dd/mm/yyyy' ), as_paytype ,as_caltype ,adc_permit ,li_install ,ldc_payment , to_date( sysdate ,'dd/mm/yyyy' ) ,'0') ;
--  ldt_startkeep := pka_lon_reqsrv.fp_rule_startkeep(as_loantype,as_memloan,to_date( sysdate ,'dd/mm/yyyy' ) ) ;
--  PKA_LON_REQSRV.sp_calc_install(as_memloan, as_loantype ,to_date( sysdate ,'dd/mm/yyyy' ), as_paytype ,as_caltype ,adc_permit ,li_install ,ldc_payment , ldt_startkeep  ,'0') ;
--  
--  li_install := PKA_LON_REQSRV.fp_calc_install_value('1') ;
--  ldc_payment := PKA_LON_REQSRV.fp_calc_install_value('2') ;
--  ldc_payment_last := PKA_LON_REQSRV.fp_calc_install_value('3') ;
--  
--  if ai_install > 0 then
--    li_install := ai_install;
--  else
--    PKA_LON_REQSRV.sp_calc_install(as_memloan, as_loantype ,to_date( sysdate ,'dd/mm/yyyy' ), as_paytype ,'P' ,adc_permit ,li_install ,ldc_payment , ldt_startkeep  ,'0') ;
--    ldc_payment := PKA_LON_REQSRV.fp_calc_install_value('2') ;
--    ldc_payment_last := PKA_LON_REQSRV.fp_calc_install_value('3') ;
--  end if;
--
--  
--  
--  li_maxinstall := pka_lon_reqsrv.fp_calc_install_max(as_memloan ,as_loantype ,to_date( sysdate ,'dd/mm/yyyy' ) ,adc_permit ,ldt_startkeep);
--  
--  if li_install > li_maxinstall then
--    li_install := li_maxinstall;
--  end if;
--
--
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'install', trim( to_char( li_install ,'999999990.99' ))  ) ;
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'payment', trim( to_char( ldc_payment ,'999999990.99' ))  ) ;
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'paymentlast', trim( to_char( ldc_payment_last ,'999999990.99' ))  ) ;  
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'startkeep', trim( PKA_COM_FUNCTION.fp_get_thaidate( PKA_SRV_DATETIME.fp_RelativeMonth( sysdate, 1 ),'MONTH YYYY')  ) ) ;
--
--  select sum(principal_balance) , sum(interest)
--  into ldc_print_bal , ldc_int_res
--  from VMB_LOAN_CLEAR
--  where membership_no = as_memloan
--  and loan_type = as_loantype
--  ;
--  
--  if ldc_print_bal is null then
--    ldc_print_bal := 0 ;
--  end if ;
--  
--  if ldc_int_res is null then
--    ldc_int_res := 0 ;
--  end if ;
--  
--  ldc_buy_share := pka_lon_reqsrv.fp_calc_loanbuyshare(as_loantype, as_memloan, adc_permit);
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'buy_share', trim(ldc_buy_share) );
--
--  ldt_start_date := to_date(sysdate,'dd/mm/yyyy');
--  -- วันที่ 1 ของเดือนถัดไป
--  ldt_next_month := to_date(TRUNC(ADD_MONTHS(ldt_start_date, 1), 'MM'),'dd/mm/yyyy');
--  
--  
--    begin
--    SELECT LOAN_INTEREST_RATE
--    into ldt_int_rate
--    FROM sc_lon_m_int_step_rate
--    WHERE LOAN_TYPE = as_loantype
--    AND effective_date = (
--        SELECT MAX(effective_date)
--        FROM sc_lon_m_int_step_rate
--        WHERE LOAN_TYPE = as_loantype
--    );
--  end;
--  
-- 
--  ldc_interest_first := (ldt_next_month - ldt_start_date) * adc_permit * ldt_int_rate / 365;
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'interest_first', trim( to_char( ldc_interest_first ,'999999990.99' ))  ) ;
--
--
--  ldc_real_amount := adc_permit - ldc_interest_first - ldc_print_bal - ldc_int_res - ldc_buy_share ;
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'real_amount', trim(ldc_real_amount) );
--  
--  
--
--  --จัดการ Array ใน Array มี , ได้ ถ้าเข้า fp_KeyValueSet มันจะแปลง , เป็น !CMA! ต้องเอามาบวกข้างนอก
--  ls_arg := PKA_MOBILE.fp_KeyValueSet(ls_arg,'fee_array', trim( 'ARRAY' )  ) ;   
--
--  ls_arg := '{'||ls_arg||'}' ; 
--
--  --จัดการ Array ใน Array มี , ได้ ถ้าเข้า fp_KeyValueSet มันจะแปลง , เป็น !CMA! ต้องเอามาบวกข้างนอก
--  select replace( ls_arg , 'ARRAY' , '' ) into ls_arg  from dual ;
--  ls_arg := substr(ls_arg , 1, len(ls_arg) - 3 ) ;
--  ls_arg := ls_arg || fp_calc_fee( as_memloan , as_loantype , adc_permit   ) ||'}';
--
--  return ls_arg ; 
--
--end fp_calc_install ;

--------------------------------------------------------------------------------
--Niorn 2023-05-05 คำนวณค่าธรรมเนียมการกู้ เป็น array
-- คำนวณ ค่าธรรมเนียมการกู้
--------------------------------------------------------------------------------
--function fp_calc_fee( as_memloan varchar2 , as_loantype varchar2    , adc_permit number  ) return varchar2  as
--type cur is ref cursor ;lcur cur;
--ls_arg varchar(4000);
--ls_sql varchar2(1000);
--ls_rc varchar2(4000);
--ls_fee_amount varchar2(4000);
--
--begin
--
--    ls_arg := null ;
--    ls_arg := pka_srv_string.fp_setkeyvalue(ls_arg,'membership_no',trim(as_memloan)); 
--    ls_arg := pka_srv_string.fp_setkeyvalue(ls_arg,'loan_type',trim(as_loantype)); 
--    ls_arg := pka_srv_string.fp_setkeyvalue(ls_arg,'requestment_date',trim(to_char(sysdate,'dd/mm/yyyy') )); 
--    ls_arg := pka_srv_string.fp_setkeyvalue(ls_arg,'loan_request_amount',trim(adc_permit)); 
--    ls_arg := pka_srv_string.fp_setkeyvalue(ls_arg,'total_share_value',trim(  PKA_LON_REQSRV.fp_calc_loanreq_member_share(as_loantype ,as_memloan ) )); 
--    ls_arg := pka_srv_string.fp_setkeyvalue(ls_arg,'buy_share',trim(0)); 
--    PKA_LON_REQFEE.sp_install_reqarg(ls_arg );
--
--    ls_arg := '' ;
--    for dr  in ( 
--        select  sc_lon_m_ucf_fee.fee_type , sc_lon_m_ucf_fee.fee_name ,sc_lon_m_ucf_fee.calc_fee 
--        from sc_lon_m_rule_fee
--        ,sc_lon_m_ucf_fee        
--        where 1=1
--        and sc_lon_m_ucf_fee.fee_type = sc_lon_m_rule_fee.loan_fee_type
--        and sc_lon_m_rule_fee.on_firstload = '1'
--        and loan_type = as_loantype   
--        order by sc_lon_m_ucf_fee.fee_type
--      ) loop
--
--
--        ls_sql := 'select '||trim(dr.calc_fee)||' from dual ';
--        open lcur for ls_sql ; fetch lcur into ls_rc ; close lcur ;
--
--        ls_fee_amount  := pka_srv_string.fp_GetKeyValue(ls_rc,'fee_amount');
--
--        ls_rc := null ;
--        if len( trim( ls_arg )) = 0 or ls_arg is null then 
--            null;
--        else
--            ls_arg := ls_arg || ',' ;
--        end if ;
--        ls_rc := PKA_MOBILE.fp_KeyValueSet(ls_rc,'fee_type', trim( dr.fee_type ) ) ;
--        ls_rc := PKA_MOBILE.fp_KeyValueSet(ls_rc,'fee_name', trim( dr.fee_name ) ) ;
--        ls_rc := PKA_MOBILE.fp_KeyValueSet(ls_rc,'fee_amount', trim( ls_fee_amount ) ) ;
--        ls_arg := ls_arg || '{'||ls_rc ||'}';
--    end loop ;
--
--  return '['||ls_arg||']' ;  
--
--end ;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------    
END PKA_MOBILE_REQSRV;
