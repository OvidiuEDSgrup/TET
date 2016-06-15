--***
create function soldvaluta (@cCont varchar(40), @cValuta char(3), @dData datetime, @cTipSold char(1))  
returns float as
begin 
 return 
 (
  select (case when @cTipSold='D' then Sold_debitor when @cTipSold='C' then Sold_creditor 
   when Sold_debitor>0 then Sold_debitor else Sold_creditor end)
  from dbo.SolduriCont(@cCont, @cValuta, @dData, '', '')
 )
end
