--***
create function soldcont (@cCont varchar(40),@dData datetime,@cTipSold char(1)) 
returns float as
-- cTipSold poate fi R - sold curent, D - debit, C -credit
begin

 return 
 (
  select (case when @cTipSold='D' then Sold_debitor when @cTipSold='C' then Sold_creditor 
   when Sold_debitor>0 then Sold_debitor else Sold_creditor end)
  from dbo.SolduriCont(@cCont, '', @dData, '', '')
 )
/*
   declare @arbcnt table (cont varchar(40))
   insert into @arbcnt
   (cont)
   select cont 
      from dbo.arbconturi(@cCont)

   declare @cTipC char(1),@nSuma float,@boyData datetime,@bomData datetime, @DataAnt datetime 
      set @boyData='01/01/'+str(year(@dData))
      set @bomData=str(month(@dData))+'/01/'+str(year(@dData))
      set @DataAnt=DateAdd(day, -1, @dData) 
      set @cTipC=(select max(tip_cont) from conturi where cont=rtrim(@cCont))
      if @cTipSold='R' --Sold Curent
            begin
                  set @nSuma=isnull((select sum(rulaj_debit-rulaj_credit) from rulaje where cont=@cCont and valuta='' and data>=@boyData and data<=(case when @dData=@boyData then @dData else @DataAnt end)), 0)
                  set @nSuma=@nSuma+isnull((select sum(suma) from pozincon where data between @bomData and @DataAnt and cont_debitor in (select cont from @arbcnt)),0)-
                        isnull((select sum(suma) from pozincon where data between @bomData and @DataAnt and cont_creditor in (select cont from @arbcnt)),0)
                  if (@cTipC='B' and @nSuma<0) or (@cTipC='P' and @nSuma<0)
                              set @nSuma=-@nSuma
            end
      ELSE
            BEGIN
                  if @cTipSold='D'
                        begin
                              set @nSuma=isnull((select sum(rulaj_debit-rulaj_credit) from rulaje where cont=@cCont and valuta='' and data>=@boyData and data<=(case when @dData=@boyData then @dData else @DataAnt end)), 0)
                              set @nSuma=@nSuma+isnull((select sum(suma) from pozincon where data between @bomData and @DataAnt and cont_debitor in (select cont from @arbcnt)),0)-
                                    isnull((select sum(suma) from pozincon where data between @bomData and @DataAnt and cont_creditor in (select cont from @arbcnt)),0)
                              if @cTipC='P'
                              begin
                                    set @nSuma=0
                              end
                              if @cTipC='B'
                              begin
                                    if @nSuma<0 set @nSuma=0
                              end
                        end
                        else
                        begin
                              set @nSuma=isnull((select sum(rulaj_credit-rulaj_debit) from rulaje where cont=@cCont and valuta='' and data>=@boyData and data<=(case when @dData=@boyData then @dData else @DataAnt end)), 0)
                              set @nSuma=@nSuma+isnull((select sum(suma) from pozincon where data between @bomData and @DataAnt and cont_creditor in (select cont from @arbcnt)),0)-
                                    isnull((select sum(suma) from pozincon where data between @bomData and @DataAnt and cont_debitor in (select cont from @arbcnt)),0)
                              if @cTipC='A'
                              begin
                                    set @nSuma=0
                              end
                              if @cTipC='B'
                              begin
                                    if @nSuma<0 set @nSuma=0
                              end
                        end
                  end
return @nSuma     
*/
END
