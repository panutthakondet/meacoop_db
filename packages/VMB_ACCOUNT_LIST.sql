
  CREATE OR REPLACE FORCE VIEW "DBO"."VMB_ACCOUNT_LIST" ("COOP_ACCOUNT_TYPE", "COOP_ACCOUNT_DESC", "CLOSE_STATUS", "COOP_ACCOUNT_STATUS", "COOP_ACCOUNT_NO", "COOP_ACCOUNT_NAME", "ACCOUNT_BALANCE", "AVALIABLE_BALANCE", "OUTSTANDING_BALANCE", "MOBILE_FLAG", "WITHDRAW_FLAG", "DEPOSIT_FLAG", "MEMBER_CODE", "CITIZEN_NO", "MOBILE_CHK") AS 
  select tb."COOP_ACCOUNT_TYPE",tb."COOP_ACCOUNT_DESC",tb."CLOSE_STATUS",tb."COOP_ACCOUNT_STATUS",tb."COOP_ACCOUNT_NO",tb."COOP_ACCOUNT_NAME",tb."ACCOUNT_BALANCE",tb."AVALIABLE_BALANCE",tb."OUTSTANDING_BALANCE",tb."MOBILE_FLAG",tb."WITHDRAW_FLAG",tb."DEPOSIT_FLAG",tb."MEMBER_CODE",tb."CITIZEN_NO",tb."MOBILE_CHK"
from ( 
  SELECT 'SAVING' as COOP_ACCOUNT_TYPE
  ,sc_dep_m_rule.deposit_name as COOP_ACCOUNT_DESC
  ,sc_dep_m_creditor.close_status as CLOSE_STATUS
  ,decode( sc_dep_m_creditor.close_status , '0' , 'ACTIVE' , 'INACTIVE') as COOP_ACCOUNT_STATUS
  ,sc_dep_m_creditor.deposit_account_no as COOP_ACCOUNT_NO
  ,sc_dep_m_creditor.deposit_account_name as COOP_ACCOUNT_NAME
  ,sc_dep_m_creditor.deposit_balance as ACCOUNT_BALANCE
  ,sc_dep_m_creditor.withdrawable_amount - sc_dep_m_rule.minimum_balance_total as AVALIABLE_BALANCE
  , 0 as OUTSTANDING_BALANCE
  ,sc_dep_m_rule.mobile_status  as MOBILE_FLAG
  ,sc_dep_m_rule.withdraw_flag as WITHDRAW_FLAG
  ,sc_dep_m_rule.deposit_flag as DEPOSIT_FLAG
  , sc_mem_m_membership_registered.membership_no as MEMBER_CODE
  , sc_mem_m_membership_registered.id_card as CITIZEN_NO
  , nvl(( select mobile_dep
      from sc_mobile_regis 
      where membership_no = sc_mem_m_membership_registered.membership_no 
      and close_status = '0'
    ),'N') as MOBILE_CHK
  from sc_mem_m_membership_registered
  ,sc_dep_m_creditor
  ,sc_dep_m_rule
  where sc_mem_m_membership_registered.membership_no = sc_dep_m_creditor.membership_no
  and sc_dep_m_creditor.deposit_type_code = sc_dep_m_rule.deposit_type_code
  and sc_dep_m_creditor.deposit_balance > 0 
  and sc_dep_m_creditor.close_status ='0'  
  and ( case 
  when sc_mem_m_membership_registered.membership_no in ('018834','023517') then sc_dep_m_rule.mobile_bay_status
  when ( sc_mem_m_membership_registered.mobile_dep = 'Y' ) then sc_dep_m_rule.mobile_bay_status
      else 
      sc_dep_m_rule.mobile_status
      end ) = 'Y'
  and (sc_dep_m_creditor.join_status ='1' 
  or (
    CASE -- ให้บัญชีที่ไม่ใช้ Promoney สามารถรับโอนภายในได้
        WHEN (
            SELECT
                COUNT(membership_no)
            FROM
                sc_mobile_regis
            WHERE
                membership_no = sc_dep_m_creditor.membership_no
                AND close_status = '0'
        ) = 0 THEN
            '1'
        ELSE
            '0'
    END
) = '1')

union all

  SELECT 'LOAN' as COOP_ACCOUNT_TYPE
  ,sc_lon_m_rule.loan_type_description as COOP_ACCOUNT_DESC
  ,sc_lon_m_loan_card.close_status as CLOSE_STATUS
  ,decode( sc_lon_m_loan_card.close_status , '0' , 'ACTIVE' , 'INACTIVE' ) as COOP_ACCOUNT_STATUS  
  --, 'ACTIVE'  as COOP_ACCOUNT_STATUS  
  ,sc_lon_m_loan_card.loan_contract_no as COOP_ACCOUNT_NO
  ,sc_lon_m_rule.loan_type_description as COOP_ACCOUNT_NAME
  ,sc_lon_m_contract.loan_approve_amount as ACCOUNT_BALANCE  
  ,decode( sc_lon_m_rule.withdraw_flag , 'N' , 0 , sc_lon_m_contract.loan_approve_amount - sc_lon_m_loan_card.principal_balance ) as AVALIABLE_BALANCE

  ,sc_lon_m_loan_card.principal_balance as OUTSTANDING_BALANCE
  ,sc_lon_m_rule.mobile_status as MOBILE_FLAG
  ,sc_lon_m_rule.withdraw_flag as WITHDRAW_FLAG
  ,sc_lon_m_rule.deposit_flag as DEPOSIT_FLAG
  , sc_mem_m_membership_registered.membership_no as MEMBER_CODE
  , sc_mem_m_membership_registered.id_card as CITIZEN_NO
    , nvl(( select mobile_lon
      from sc_mobile_regis 
      where membership_no = sc_mem_m_membership_registered.membership_no 
      and close_status = '0'
    ),'N') as MOBILE_CHK
  from sc_mem_m_membership_registered
  ,sc_lon_m_loan_card
  ,sc_lon_m_rule
  ,sc_lon_m_contract
  where sc_mem_m_membership_registered.membership_no = sc_lon_m_loan_card.membership_no
  and sc_lon_m_loan_card.loan_type = sc_lon_m_rule.loan_type
  and sc_lon_m_loan_card.loan_contract_no = sc_lon_m_contract.loan_contract_no  
  and (  sc_lon_m_loan_card.principal_balance > 0  or ( ( sc_lon_m_rule.atm_status = '1' or sc_lon_m_rule.loan_looping = '1' ) and sc_lon_m_loan_card.close_status = '0'
    )  )
  and ( case 
            when sc_mem_m_membership_registered.membership_no in ('018834','023517') then sc_lon_m_rule.mobile_status
            when ( sc_mem_m_membership_registered.mobile_lon = 'Y' or sc_mem_m_membership_registered.mobile_dep = 'Y' ) then 
             case
             when ( sc_mem_m_membership_registered.mobile_lon = 'Y' ) then sc_lon_m_rule.mobile_bay_status
             else 'N'
             end
             when ( sc_mem_m_membership_registered.mobile_lon = 'N' and sc_mem_m_membership_registered.mobile_dep = 'N' ) then 
             case
             when ( select count(*) from sc_mobile_regis where close_status = '0' and membership_no = sc_mem_m_membership_registered.membership_no) > 0 then 'Y'
             else 'N'
             end
        else 
            sc_lon_m_rule.mobile_status
        end ) = 'Y'
)  tb
WHERE 1=1
--and member_code = '023517'
 ;
 

