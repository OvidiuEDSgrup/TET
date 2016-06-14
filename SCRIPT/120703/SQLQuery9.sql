--***  
create function cautareCodIntrare (@Cod char(20), @Gestiune char(9), @TipGestiune char(1), @CodIntrarePred char(13),   
@PretStoc float, @PretAmanunt float, @ContStoc char(13), @CodIntrareNou int,   
@StocPozitiv int, @DataJosStocuri datetime, @DataSusStocuri datetime, @Locatie char(13), @LM char(9),   
@Comanda char(40), @Contract char(20), @Furnizor char(20), @Lot char(20))   
returns char(13) as   
begin  
 declare @CodIntrare char(13), @Sb char(9)  
   
 select @StocPozitiv=isnull(@StocPozitiv, 0), @DataJosStocuri=isnull(@DataJosStocuri, '01/01/1901'), @DataSusStocuri=isnull(@DataSusStocuri, '01/01/1901'),   
  @Locatie=isnull(@Locatie, ''), @LM=isnull(@LM, ''), @Comanda=isnull(@Comanda, ''),   
  @Contract=isnull(@Contract, ''), @Furnizor=isnull(@Furnizor, ''), @Lot=isnull(@Lot, '')  
   
 set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')  
 if isnull(@TipGestiune, '')=''  
  set @TipGestiune=isnull((select max(tip_gestiune) from gestiuni where subunitate=@Sb and cod_gestiune=@Gestiune), '')  
   
 set @CodIntrare=@CodIntrarePred  
 declare @pas int  
 set @pas=0  
 while @TipGestiune<>'V' and @pas<702   
  and exists (select 1 from stocuri where subunitate=@Sb and tip_gestiune=@TipGestiune and cod_gestiune=@Gestiune and cod=@Cod and cod_intrare=@CodIntrare  
   and (@CodIntrareNou=1   
    or abs(@PretStoc-pret)>=0.00001   
    or isnull(@ContStoc, '')<>'' and cont<>@ContStoc   
    or @TipGestiune='A' and isnull(@PretAmanunt,0)<>0 and abs(pret_cu_amanuntul-isnull(@PretAmanunt,0))>=0.001   
    or @StocPozitiv=1 and stoc<=-0.001   
    or @DataJosStocuri>'01/01/1921' and data>@DataJosStocuri   
    or @DataSusStocuri>'01/01/1921' and data<@DataSusStocuri   
    or @Locatie<>'' and locatie<>@Locatie   
    or @LM<>'' and loc_de_munca<>@LM   
    or @Comanda<>'' and comanda<>@Comanda   
    or @Contract<>'' and contract<>@Contract   
    or @Furnizor<>'' and furnizor<>@Furnizor   
    or @Lot<>'' and lot<>@Lot  
    )  
   )  
 begin  
  set @pas=@pas+1  
  set @CodIntrare=RTrim(left(@CodIntrarePred,(case when @pas<=26 then 12 else 11 end)))+RTrim((case when @pas>26 then CHAR(64+(@pas-1)/26) else '' end))+CHAR(64+(@pas-1)%26+1)  
 end  
   
 return @CodIntrare  
end  