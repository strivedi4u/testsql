create or replace procedure SP_NBS_NEW_MINS as
BEGIN
  for cursor1 in(select SEQ_NBSNEWMINS_TRXNID.nextval TRXNID,
    PE.INS_CO_REFNO AS MINS_POLICY_NO,
    PD.risk_expiry_DATE  as MINS_EXP_DATE ,
    PD.ISSUE_DATE AS MINS_ISSUE_DATE,--Added By Rohitash on 04-JULY-2018 MINS-13426
    PD.RISK_INCEPTION_DATE AS MINS_INCEPTION_DATE,--Added By Rohitash on 04-JULY-2018 MINS-13426
    VD.VEHICLE_TYPE AS MINS_VEHICLE_TYPE,----Added By Rohitash on 04-JULY-2018 MINS-13426
        VEHICLE_SALE_DATE as MINS_SALE_DATE ,
       case policy_selection
       when 'F1' then 'F'
       when 'F2' then 'F'
       when 'F3' then 'R'
       when 'F4' then 'R'
       when 'R' then 'R'
       when 'N' then 'R'
       when 'T' then 'T'
       end as MINS_RENEW_FLAG ,
        IC.name As MINS_INS_COMP,
----CHanged by Amit as suggested by Sachin on 23-NOV-2009 as some problem is coming in DMS
 --BM.NAME as MINS_BRANCH_NAME,
 NVL(BM.NAME,'OTHERS') as MINS_BRANCH_NAME,
 ----End of Change
case DOM.Outlet_Code when 123 then 'N' when 617 then 'N' else 'D' end AS MINS_PART_TYPE,
-------Added by Amit against SR-INS-08-1843 to take the partycode and forcode from Party_Parent_Outlet ------
---DOM.PARTY_CODE as  MINS_PARTY_CD,
---CM.FOR_CODE as  MINS_PARTY_FORCODE ,
PPO.PARTY_CODE as  MINS_PARTY_CD,
PPO.Forcode as  MINS_PARTY_FORCODE ,
 ------End of SR-INS-08-1843---------------------
CHASSIS_NO as MINS_CHASSIS,
SM.MODEL_NO as MINS_BASIC_MODEL,
ENGINE_NO as MINS_ENG_NUM,
REGN_NO_FOR_SEARCH as MINS_REG_NUM,
PCD.TITLE AS MINS_CUST_TITLE,
CASE PCD.CUST_TYPE WHEN 'I' THEN  PCD.FIRST_NAME||' '|| PCD.MIDDLE_NAME||' '|| PCD.LAST_NAME  ELSE  PCD.CORPORATE_NAME END AS MINS_CUST_NAME,
REPLACE(SUBSTR(PCD.Address,1,50),'''',' ') as MINS_CUST_ADDRESS1,
 REPLACE(SUBSTR(PCD.Address,51,100),'''',' ') as MINS_CUST_ADDRESS2,
 REPLACE(SUBSTR(PCD.Address,101,150),'''',' ') as MINS_CUST_ADDRESS3,
CM.Name as MINS_CUST_CITY,
PCD.PIN as MINS_CUST_PIN,
PCD.EMAIL_ID  as MINS_CUST_EMAIL,
PCD.phone_no as MINS_CUST_PHONE,
PCD.MOBILE as MINS_CUST_MOBILE,
SYSDATE as MINS_TIMESTAMP,
NULL as MINS_BATCHPICKED_DATE,
'N' AS MINS_BATCHPICKED_FLAG,
NULL AS MINS_REASON,
'N' AS Transaction_Type,
VD.VIN_NO,
'N' AS CANCELLATION_STATUS,
'0' MINS_TIMESTAMP_UPDATE,
case when pcd.isretaildone='N' then '0' else '1' end as MINS_RETAIL_FLAG,
case when pcd.Isnamechange='N' then '0'else '1' end as MINS_NAME_FLAG
--Added by Pooja on 14-may-2015 against MINS-13209
,pd.premium as MINS_PREMIUM,
pd.service_tax_amount as MINS_SERVICE_TAX_AMOUNT,
/*Added by Manish related to GST against SCRNO:MINS-13375*/
PD.IGST_AMOUNT as MINS_IGST_AMOUNT,
PD.CGST_AMOUNT as MINS_CGST_AMOUNT,
PD.SGST_AMOUNT as MINS_SGST_AMOUNT,
PD.UGST_AMOUNT as MINS_UGST_AMOUNT
--End of Changes Added by Pooja on 14-may-2015 against MINS-13209
,ddom.mul_dealer_cd,ddom.for_cd --change by Rameshwar Rai for scr MINS-13647 Date :07-Jul-2020
,dom.outlet_name as MI_DEALER_NAME
,dom.outlet_code as MI_DEALER_OUTLETCODE
,dom.mobile as MI_DEALER_CONTACTDETAILS
,cm.region_id as REGION_CODE
,(case when  cm.principal_code=1 then '4W' else '2W' end) MINS_BUSINESSTYPE
,PP.TOTAL_OD AS TOTAL_OD --ADDED BY SABITA FOR LOYALTY POINTS 24-11-2022
,PP.TOTAL_TP AS TOTAL_TP
FROM POLICY PD
INNER JOIN POLICY_EXTENDED PE ON PD.CURRENT_POLICY_NO=PE.CURRENT_POLICY_NO
INNER JOIN MIN_CCA_PROPOSAL_ALLOCATION CCP ON CCP.CURRENT_POLICY_NO=PD.CURRENT_POLICY_NO
    INNER JOIN POLICY_VEHICLE VD ON PD.CURRENT_POLICY_NO = VD.CURRENT_POLICY_NO
    INNER JOIN POLICY_PAYMENT_DETAILS PAY  ON PD.CURRENT_POLICY_NO = PAY.CURRENT_POLICY_NO
    INNER JOIN DEALER_OUTLET_MASTER DOM ON PD.OUTLET_CODE = DOM.OUTLET_CODE
    -------Added by Amit against SR-INS-08-1843 to take the partycode and forcode from Party_Parent_Outlet ------
    Inner join Party_Parent_Outlet PPO on PPO.Outlet_Code = DOM.Outlet_Code
    ------End of SR-INS-08-1843---------------------
    inner  Join POLICY_Client_DETAILS PCD   ON PD.CURRENT_POLICY_NO = PCD.CURRENT_POLICY_NO
    INNER JOIN SUB_MODEL_MASTER SM ON SM.SUB_MODEL_NO = VD.SUB_MODEL_NO
    INNER JOIN CITY_master CM ON CM.CITY_id = DOM.CITY_id
    INNER JOIN POLICY_PREMIUM PP ON PD.CURRENT_POLICY_NO=PP.CURRENT_POLICY_NO --ADDED BY SABITA FOR LOYALTY POINTS 24-11-2022
    inner join insurance_company IC on IC.company_id=PD.company_id
    left join bank_master BM on BM.bank_id=PAY.INSTRUMENT_BANK
    left join Min_Dms_Dealer_Outlet_Mapping ddom on ddom.outlet_code=pd.outlet_code --change by Rameshwar Rai for scr MINS-13647 Date :07-Jul-2020
        where --PD.issue_date >=trunc(sysdate-1) --Commented by Rohitash on 18-Nov-2023
        PE.INS_APPROVAL_DATE>=TRUNC(SYSDATE-1) --added by Rohitash on 18-Nov-2023
        AND PD.IS_CANCELLED=0
        and NVL(CCP.IS_DMS_SEND,0)=0
        AND PE.INS_APPROVAL=1)
  loop

     insert into MIN.NBS_NEW_MINS values
     (
      cursor1.TRXNID,
    cursor1.MINS_POLICY_NO,
    cursor1.MINS_EXP_DATE ,
     cursor1.MINS_SALE_DATE ,
     cursor1.MINS_RENEW_FLAG ,
     cursor1.MINS_INS_COMP,
----CHanged by Amit as suggested by Sachin on 23-NOV-2009 as some problem is coming in DMS
 --BM.NAME as MINS_BRANCH_NAME,
cursor1.MINS_BRANCH_NAME,
 ----End of Change
cursor1.MINS_PART_TYPE,
-------Added by Amit against SR-INS-08-1843 to take the partycode and forcode from Party_Parent_Outlet ------
---DOM.PARTY_CODE as  MINS_PARTY_CD,
---CM.FOR_CODE as  MINS_PARTY_FORCODE ,
cursor1.MINS_PARTY_CD,
cursor1.MINS_PARTY_FORCODE ,
 ------End of SR-INS-08-1843---------------------
cursor1.MINS_CHASSIS,
cursor1.MINS_BASIC_MODEL,
cursor1.MINS_ENG_NUM,
cursor1.MINS_REG_NUM,
cursor1.MINS_CUST_TITLE,
cursor1.MINS_CUST_NAME,
cursor1.MINS_CUST_ADDRESS1,
cursor1.MINS_CUST_ADDRESS2,
cursor1.MINS_CUST_ADDRESS3,
cursor1.MINS_CUST_CITY,
cursor1.MINS_CUST_PIN,
cursor1.MINS_CUST_EMAIL,
cursor1.MINS_CUST_PHONE,
cursor1.MINS_CUST_MOBILE,
cursor1.MINS_TIMESTAMP,
cursor1.MINS_BATCHPICKED_DATE,
cursor1.MINS_BATCHPICKED_FLAG,
cursor1.MINS_REASON,
cursor1.Transaction_Type,
cursor1.VIN_NO,
cursor1.CANCELLATION_STATUS,
cursor1.MINS_TIMESTAMP_UPDATE,
cursor1.MINS_RETAIL_FLAG,
cursor1.MINS_NAME_FLAG,
--Added by Pooja on 14-may-2015 against MINS-13209
cursor1.mins_premium,
cursor1.Mins_Service_Tax_Amount,
/*Added by Manish related to GST against SCRNO:MINS-13375*/
cursor1.Mins_Igst_Amount,
cursor1.Mins_Cgst_Amount,
cursor1.Mins_Sgst_Amount,
cursor1.Mins_Ugst_Amount,
CURSOR1.MINS_ISSUE_DATE,--Added By Rohitash on 04-JULY-2018
CURSOR1.MINS_INCEPTION_DATE,--Added By Rohitash on 04-JULY-2018
CURSOR1.MINS_VEHICLE_TYPE --Added By Rohitash on 04-JULY-2018
--End of Changes Added by Pooja on 14-may-2015 against MINS-13209
,CURSOR1.Mul_Dealer_Cd,CURSOR1.For_Cd --change by Rameshwar Rai for scr MINS-13647 Date :07-Jul-2020
,CURSOR1.MI_DEALER_NAME
,CURSOR1.MI_DEALER_OUTLETCODE
,CURSOR1.MI_DEALER_CONTACTDETAILS
,CURSOR1.REGION_CODE
,CURSOR1.MINS_BUSINESSTYPE
,CURSOR1.TOTAL_OD  ----ADDED BY SABITA FOR LOYALTY POINTS 24-11-2022
,CURSOR1.TOTAL_TP
);


      update min_cca_proposal_allocation ccp
      set  CCP.IS_DMS_SEND=1,
      CCP.IS_DMSUPDATEDDATE= sysdate,
      CCP.IS_DMSUPDATEDBY='AUTO_DMS_JOB'
      WHERE CURRENT_POLICY_NO=
      (
      select pe.current_policy_no from policy_extended pe
      where pe.ins_co_refno=cursor1.MINS_POLICY_NO
      );

  end loop;


   for cursor2 in(select SEQ_NBSNEWMINS_TRXNID.nextval TRXNID,
    PE.INS_CO_REFNO AS MINS_POLICY_NO,
    PD.risk_expiry_DATE  as MINS_EXP_DATE ,
    PD.ISSUE_DATE AS MINS_ISSUE_DATE,
    PD.RISK_INCEPTION_DATE AS MINS_INCEPTION_DATE,
    VD.VEHICLE_TYPE AS MINS_VEHICLE_TYPE,
        VEHICLE_SALE_DATE as MINS_SALE_DATE ,
       case policy_selection
       when 'F1' then 'F'
       when 'F2' then 'F'
       when 'F3' then 'R'
       when 'F4' then 'R'
       when 'R' then 'R'
       when 'N' then 'R'
       when 'T' then 'T'
       end as MINS_RENEW_FLAG ,
        IC.name As MINS_INS_COMP,
 NVL(BM.NAME,'OTHERS') as MINS_BRANCH_NAME,
case DOM.Outlet_Code when 123 then 'N' when 617 then 'N' else 'D' end AS MINS_PART_TYPE,
PPO.PARTY_CODE as  MINS_PARTY_CD,
PPO.Forcode as  MINS_PARTY_FORCODE ,
CHASSIS_NO as MINS_CHASSIS,
SM.MODEL_NO as MINS_BASIC_MODEL,
ENGINE_NO as MINS_ENG_NUM,
REGN_NO_FOR_SEARCH as MINS_REG_NUM,
PCD.TITLE AS MINS_CUST_TITLE,
CASE PCD.CUST_TYPE WHEN 'I' THEN  PCD.FIRST_NAME||' '|| PCD.MIDDLE_NAME||' '|| PCD.LAST_NAME  ELSE  PCD.CORPORATE_NAME END AS MINS_CUST_NAME,
REPLACE(SUBSTR(PCD.Address,1,50),'''',' ') as MINS_CUST_ADDRESS1,
 REPLACE(SUBSTR(PCD.Address,51,100),'''',' ') as MINS_CUST_ADDRESS2,
 REPLACE(SUBSTR(PCD.Address,101,150),'''',' ') as MINS_CUST_ADDRESS3,
CM.Name as MINS_CUST_CITY,
PCD.PIN as MINS_CUST_PIN,
PCD.EMAIL_ID  as MINS_CUST_EMAIL,
PCD.phone_no as MINS_CUST_PHONE,
PCD.MOBILE as MINS_CUST_MOBILE,
SYSDATE as MINS_TIMESTAMP,
NULL as MINS_BATCHPICKED_DATE,
'N' AS MINS_BATCHPICKED_FLAG,
NULL AS MINS_REASON,
'N' AS Transaction_Type,
VD.VIN_NO,
'L' AS CANCELLATION_STATUS,
'0' MINS_TIMESTAMP_UPDATE,
case when pcd.isretaildone='N' then '0' else '1' end as MINS_RETAIL_FLAG,
case when pcd.Isnamechange='N' then '0'else '1' end as MINS_NAME_FLAG
,pd.premium as MINS_PREMIUM,
pd.service_tax_amount as MINS_SERVICE_TAX_AMOUNT,
PD.IGST_AMOUNT as MINS_IGST_AMOUNT,
PD.CGST_AMOUNT as MINS_CGST_AMOUNT,
PD.SGST_AMOUNT as MINS_SGST_AMOUNT,
PD.UGST_AMOUNT as MINS_UGST_AMOUNT
, '9967' as mul_dealer_cd
 ,'95'  as for_cd
 ,dom.outlet_name as MI_DEALER_NAME
,dom.outlet_code as MI_DEALER_OUTLETCODE
,dom.mobile as MI_DEALER_CONTACTDETAILS
,cm.region_id as REGION_CODE
,(case when  cm.principal_code=1 then '4W' else '2W' end) MINS_BUSINESSTYPE
,PP.TOTAL_OD AS TOTAL_OD
,PP.TOTAL_TP AS TOTAL_TP
FROM POLICY PD
INNER JOIN POLICY_EXTENDED PE ON PD.CURRENT_POLICY_NO=PE.CURRENT_POLICY_NO
INNER JOIN MIN_CCA_PROPOSAL_ALLOCATION CCP ON CCP.CURRENT_POLICY_NO=PD.CURRENT_POLICY_NO
    INNER JOIN POLICY_VEHICLE VD ON PD.CURRENT_POLICY_NO = VD.CURRENT_POLICY_NO
    INNER JOIN POLICY_PAYMENT_DETAILS PAY  ON PD.CURRENT_POLICY_NO = PAY.CURRENT_POLICY_NO
    INNER JOIN POLICY_PREMIUM PP ON PD.CURRENT_POLICY_NO=PP.CURRENT_POLICY_NO
    INNER JOIN DEALER_OUTLET_MASTER DOM ON PD.OUTLET_CODE = DOM.OUTLET_CODE
    Inner join Party_Parent_Outlet PPO on PPO.Outlet_Code = DOM.Outlet_Code
    inner  Join POLICY_Client_DETAILS PCD   ON PD.CURRENT_POLICY_NO = PCD.CURRENT_POLICY_NO
    INNER JOIN SUB_MODEL_MASTER SM ON SM.SUB_MODEL_NO = VD.SUB_MODEL_NO
    INNER JOIN CITY_master CM ON CM.CITY_id = DOM.CITY_id
    inner join insurance_company IC on IC.company_id=PD.company_id
    left join bank_master BM on BM.bank_id=PAY.INSTRUMENT_BANK
    left join Min_Dms_Dealer_Outlet_Mapping ddom on ddom.outlet_code=pd.outlet_code


        where
        --PD.Issue_Date>trunc(sysdate-15)
        PE.INS_APPROVAL_DATE>=trunc(sysdate-1) --added by rohitash on 18-Nov-2023
        AND PD.IS_CANCELLED=0
        AND PE.INS_APPROVAL=1
        and nvl(ccp.is_dms_send_loyalty,0)=0
        and  pd.outlet_code=2159



        )
  loop

     insert into MIN.NBS_NEW_MINS values
     (
      cursor2.TRXNID,
    cursor2.MINS_POLICY_NO,
    cursor2.MINS_EXP_DATE ,
     cursor2.MINS_SALE_DATE ,
     cursor2.MINS_RENEW_FLAG ,
     cursor2.MINS_INS_COMP,

cursor2.MINS_BRANCH_NAME,
cursor2.MINS_PART_TYPE,

cursor2.MINS_PARTY_CD,
cursor2.MINS_PARTY_FORCODE ,
cursor2.MINS_CHASSIS,
cursor2.MINS_BASIC_MODEL,
cursor2.MINS_ENG_NUM,
cursor2.MINS_REG_NUM,
cursor2.MINS_CUST_TITLE,
cursor2.MINS_CUST_NAME,
cursor2.MINS_CUST_ADDRESS1,
cursor2.MINS_CUST_ADDRESS2,
cursor2.MINS_CUST_ADDRESS3,
cursor2.MINS_CUST_CITY,
cursor2.MINS_CUST_PIN,
cursor2.MINS_CUST_EMAIL,
cursor2.MINS_CUST_PHONE,
cursor2.MINS_CUST_MOBILE,
cursor2.MINS_TIMESTAMP,
cursor2.MINS_BATCHPICKED_DATE,
cursor2.MINS_BATCHPICKED_FLAG,
cursor2.MINS_REASON,
cursor2.Transaction_Type,
cursor2.VIN_NO,
cursor2.CANCELLATION_STATUS,
cursor2.MINS_TIMESTAMP_UPDATE,
cursor2.MINS_RETAIL_FLAG,
cursor2.MINS_NAME_FLAG,
cursor2.mins_premium,
cursor2.Mins_Service_Tax_Amount,
cursor2.Mins_Igst_Amount,
cursor2.Mins_Cgst_Amount,
cursor2.Mins_Sgst_Amount,
cursor2.Mins_Ugst_Amount,
cursor2.MINS_ISSUE_DATE,
cursor2.MINS_INCEPTION_DATE,
cursor2.MINS_VEHICLE_TYPE
,cursor2.Mul_Dealer_Cd,cursor2.For_Cd
,cursor2.MI_DEALER_NAME
,cursor2.MI_DEALER_OUTLETCODE
,cursor2.MI_DEALER_CONTACTDETAILS
,cursor2.REGION_CODE
,cursor2.MINS_BUSINESSTYPE
,CURSOR2.TOTAL_OD
,CURSOR2.TOTAL_TP
);


      update min_cca_proposal_allocation ccp
      set  CCP.Is_Dms_Send_Loyalty=1,
      CCP.IS_DMSUPDATEDDATE= sysdate,
      CCP.IS_DMSUPDATEDBY='AUTO_DMS_JOB'
      WHERE CURRENT_POLICY_NO=
      (
      select pe.current_policy_no from policy_extended pe
      where pe.ins_co_refno=cursor2.MINS_POLICY_NO
      );

  end loop;

  for cursor3 in(select SEQ_NBSNEWMINS_TRXNID.nextval TRXNID,
    PE.INS_CO_REFNO AS MINS_POLICY_NO,
    PD.risk_expiry_DATE  as MINS_EXP_DATE ,
    PD.ISSUE_DATE AS MINS_ISSUE_DATE,
    PD.RISK_INCEPTION_DATE AS MINS_INCEPTION_DATE,
    VD.VEHICLE_TYPE AS MINS_VEHICLE_TYPE,
        VEHICLE_SALE_DATE as MINS_SALE_DATE ,
       case policy_selection
       when 'F1' then 'F'
       when 'F2' then 'F'
       when 'F3' then 'R'
       when 'F4' then 'R'
       when 'R' then 'R'
       when 'N' then 'R'
       when 'T' then 'T'
       end as MINS_RENEW_FLAG ,
        IC.name As MINS_INS_COMP,
 NVL(BM.NAME,'OTHERS') as MINS_BRANCH_NAME,
case DOM.Outlet_Code when 123 then 'N' when 617 then 'N' else 'D' end AS MINS_PART_TYPE,
PPO.PARTY_CODE as  MINS_PARTY_CD,
PPO.Forcode as  MINS_PARTY_FORCODE ,
CHASSIS_NO as MINS_CHASSIS,
SM.MODEL_NO as MINS_BASIC_MODEL,
ENGINE_NO as MINS_ENG_NUM,
REGN_NO_FOR_SEARCH as MINS_REG_NUM,
PCD.TITLE AS MINS_CUST_TITLE,
CASE PCD.CUST_TYPE WHEN 'I' THEN  PCD.FIRST_NAME||' '|| PCD.MIDDLE_NAME||' '|| PCD.LAST_NAME  ELSE  PCD.CORPORATE_NAME END AS MINS_CUST_NAME,
REPLACE(SUBSTR(PCD.Address,1,50),'''',' ') as MINS_CUST_ADDRESS1,
 REPLACE(SUBSTR(PCD.Address,51,100),'''',' ') as MINS_CUST_ADDRESS2,
 REPLACE(SUBSTR(PCD.Address,101,150),'''',' ') as MINS_CUST_ADDRESS3,
CM.Name as MINS_CUST_CITY,
PCD.PIN as MINS_CUST_PIN,
PCD.EMAIL_ID  as MINS_CUST_EMAIL,
PCD.phone_no as MINS_CUST_PHONE,
PCD.MOBILE as MINS_CUST_MOBILE,
SYSDATE as MINS_TIMESTAMP,
NULL as MINS_BATCHPICKED_DATE,
'N' AS MINS_BATCHPICKED_FLAG,
NULL AS MINS_REASON,
'N' AS Transaction_Type,
VD.VIN_NO,
'L' AS CANCELLATION_STATUS,
'0' MINS_TIMESTAMP_UPDATE,
case when pcd.isretaildone='N' then '0' else '1' end as MINS_RETAIL_FLAG,
case when pcd.Isnamechange='N' then '0'else '1' end as MINS_NAME_FLAG
,pd.premium as MINS_PREMIUM,
pd.service_tax_amount as MINS_SERVICE_TAX_AMOUNT,
PD.IGST_AMOUNT as MINS_IGST_AMOUNT,
PD.CGST_AMOUNT as MINS_CGST_AMOUNT,
PD.SGST_AMOUNT as MINS_SGST_AMOUNT,
PD.UGST_AMOUNT as MINS_UGST_AMOUNT
, ddom.mul_dealer_cd
 , ddom.for_cd
  ,dom.outlet_name as MI_DEALER_NAME
,dom.outlet_code as MI_DEALER_OUTLETCODE
,dom.mobile as MI_DEALER_CONTACTDETAILS
,cm.region_id as REGION_CODE
,(case when  cm.principal_code=1 then '4W' else '2W' end) MINS_BUSINESSTYPE
,PP.TOTAL_OD AS TOTAL_OD
,PP.TOTAL_TP AS TOTAL_TP
    FROM POLICY PD
    INNER JOIN POLICY_EXTENDED PE ON PD.CURRENT_POLICY_NO=PE.CURRENT_POLICY_NO
    INNER JOIN MIN_CCA_PROPOSAL_ALLOCATION CCP ON CCP.CURRENT_POLICY_NO=PD.CURRENT_POLICY_NO
    INNER JOIN POLICY_VEHICLE VD ON PD.CURRENT_POLICY_NO = VD.CURRENT_POLICY_NO
    INNER JOIN POLICY_PAYMENT_DETAILS PAY  ON PD.CURRENT_POLICY_NO = PAY.CURRENT_POLICY_NO
    INNER JOIN POLICY_PREMIUM PP ON PD.CURRENT_POLICY_NO=PP.CURRENT_POLICY_NO
    INNER JOIN DEALER_OUTLET_MASTER DOM ON PD.OUTLET_CODE = DOM.OUTLET_CODE
    Inner join Party_Parent_Outlet PPO on PPO.Outlet_Code = DOM.Outlet_Code
    inner  Join POLICY_Client_DETAILS PCD   ON PD.CURRENT_POLICY_NO = PCD.CURRENT_POLICY_NO
    INNER JOIN SUB_MODEL_MASTER SM ON SM.SUB_MODEL_NO = VD.SUB_MODEL_NO
    INNER JOIN CITY_master CM ON CM.CITY_id = DOM.CITY_id
    inner join insurance_company IC on IC.company_id=PD.company_id
    left join bank_master BM on BM.bank_id=PAY.INSTRUMENT_BANK
    left join Min_Dms_Dealer_Outlet_Mapping ddom on ddom.outlet_code=pd.outlet_code
    left join mib_cust_pref_outlet mcp on mcp.current_policy_no=pd.current_policy_no


        where
        --PD.issue_date >=trunc(sysdate-1)
        PE.INS_APPROVAL_DATE>=trunc(sysdate-1) --added by rohitash on 18-Nov-2023
        and nvl(ccp.is_dms_send_loyalty,0)=0
        AND PD.IS_CANCELLED=0
        AND PE.INS_APPROVAL=1
        and  mcp.original_outlet_code=2159
        and nvl(mcp.status,0)=1



        )
  loop

     insert into MIN.NBS_NEW_MINS values
     (
      cursor3.TRXNID,
    cursor3.MINS_POLICY_NO,
    cursor3.MINS_EXP_DATE ,
     cursor3.MINS_SALE_DATE ,
     cursor3.MINS_RENEW_FLAG ,
     cursor3.MINS_INS_COMP,

cursor3.MINS_BRANCH_NAME,
cursor3.MINS_PART_TYPE,

cursor3.MINS_PARTY_CD,
cursor3.MINS_PARTY_FORCODE ,
cursor3.MINS_CHASSIS,
cursor3.MINS_BASIC_MODEL,
cursor3.MINS_ENG_NUM,
cursor3.MINS_REG_NUM,
cursor3.MINS_CUST_TITLE,
cursor3.MINS_CUST_NAME,
cursor3.MINS_CUST_ADDRESS1,
cursor3.MINS_CUST_ADDRESS2,
cursor3.MINS_CUST_ADDRESS3,
cursor3.MINS_CUST_CITY,
cursor3.MINS_CUST_PIN,
cursor3.MINS_CUST_EMAIL,
cursor3.MINS_CUST_PHONE,
cursor3.MINS_CUST_MOBILE,
cursor3.MINS_TIMESTAMP,
cursor3.MINS_BATCHPICKED_DATE,
cursor3.MINS_BATCHPICKED_FLAG,
cursor3.MINS_REASON,
cursor3.Transaction_Type,
cursor3.VIN_NO,
cursor3.CANCELLATION_STATUS,
cursor3.MINS_TIMESTAMP_UPDATE,
cursor3.MINS_RETAIL_FLAG,
cursor3.MINS_NAME_FLAG,
cursor3.mins_premium,
cursor3.Mins_Service_Tax_Amount,
cursor3.Mins_Igst_Amount,
cursor3.Mins_Cgst_Amount,
cursor3.Mins_Sgst_Amount,
cursor3.Mins_Ugst_Amount,
cursor3.MINS_ISSUE_DATE,
cursor3.MINS_INCEPTION_DATE,
cursor3.MINS_VEHICLE_TYPE
,cursor3.Mul_Dealer_Cd,cursor3.For_Cd
,cursor3.MI_DEALER_NAME
,cursor3.MI_DEALER_OUTLETCODE
,cursor3.MI_DEALER_CONTACTDETAILS
,cursor3.REGION_CODE
,cursor3.MINS_BUSINESSTYPE
,CURSOR3.TOTAL_OD
,CURSOR3.TOTAL_TP
);


      update min_cca_proposal_allocation ccp
      set  CCP.Is_Dms_Send_Loyalty=1,
      CCP.IS_DMSUPDATEDDATE= sysdate,
      CCP.IS_DMSUPDATEDBY='AUTO_DMS_JOB'
      WHERE CURRENT_POLICY_NO=
      (
      select pe.current_policy_no from policy_extended pe
      where pe.ins_co_refno=cursor3.MINS_POLICY_NO
      );

  end loop;

  end;
