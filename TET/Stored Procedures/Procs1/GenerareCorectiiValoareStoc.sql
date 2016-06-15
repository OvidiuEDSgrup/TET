--***
create procedure GenerareCorectiiValoareStoc @datacorectii datetime,@nrcorectii char(20)='INV',
@ctcorectii varchar(40)='6588',@gestfiltru char(9)='',@codfiltru char(20)='',@parXML XML=''
-- aceasta procedura ("scriptul lui Luci") genereaza doc. de corectie la zerorizarea gestiunilor, daca 
--au fost necorelatii, adica stoc total pe (gestiune, cod) este egal cu zero, iar valoarea este 
--diferita de zero 
as 
BEGIN
begin try 
if exists (select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>'')
begin
		raiserror('Accesul este restrictionat pe anumite gestiuni! Nu este permisa operatia in aceste conditii!',16,1)
		return
end

if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
end

declare @gest char(9), @tipgest char(1), @Cod char(20), @ValoareStoc float, @ContStoc varchar(40), 
@PStocIntrari float, @CodIntrareIntrari char(13), @PStocIesiri float, @CodIntrareIesiri char(13)

set @gestfiltru=(case when @gestfiltru='' then null else @gestfiltru end)
set @codfiltru=(case when @codfiltru='' then null else @codfiltru end)

	declare @p xml
	select @p=(select @datacorectii dDataSus, @codfiltru cCod, @gestfiltru cGestiune, 'D' TipStoc, 0 Corelatii for xml raw)

	if object_id('tempdb..#docstoc') is not null drop table #docstoc
		create table #docstoc(subunitate varchar(9))
		exec pStocuri_tabela
	 
	exec pstoc @sesiune='', @parxml=@p

declare crsstoc cursor for
select gestiune, max(tip_gestiune), cod, sum(round(convert(decimal(15, 5), 
round(convert(decimal(15,5), (case when s.tip_miscare='E' then -1 else 1 end)*s.cantitate),3)*pret),5))
--from dbo.fStocuri(null, @datacorectii, @codfiltru, @gestfiltru, null, null, 'D', null, 0, null, null, null, null, null, null, null) s
from #docstoc s
group by gestiune, cod
having abs(sum(round(convert(decimal(15,5), (case when s.tip_miscare='E' then -1 else 1 
end)*s.cantitate), 3)))<0.001 and abs(sum(round(convert(decimal(15, 5), round(convert(decimal(15,5), 
(case when s.tip_miscare='E' then -1 else 1 end)*s.cantitate), 3)*pret), 5)))>=0.01
order by 1, 3

open crsstoc
fetch next from crsstoc into @gest, @tipgest, @Cod, @ValoareStoc
while @@fetch_status=0
begin
      select @ContStoc=dbo.formezContStoc(@gest, @Cod, ''), 
            @PStocIntrari=(case when @ValoareStoc<0 then abs(@ValoareStoc) else 0 end), 
            @PStocIesiri=(case when @ValoareStoc>0 then @ValoareStoc else 0 end), 
            @CodIntrareIntrari=dbo.cautareCodIntrare(@Cod, @gest, @tipgest, 'NECORELP', @PStocIntrari, 0, @ContStoc, 0, 0, @datacorectii, @datacorectii, '', '', '', '', '', '')
      exec scriuAE @Numar=@nrcorectii, @Data=@datacorectii, @gest=@gest, @Cod=@Cod, @CodIntrare=@CodIntrareIntrari, 
            @Cantitate=-1, @CtCoresp=@ctcorectii, @LM='', @Comanda='', @ComLivr='', @Explicatii='Corectii valoare stoc', 
            @Serie='', @Utilizator='CGplus', @Schimb=0, @Jurnal='', @Stare=5, @NrPozitie=null, @PozitieNoua=1, @PretStoc=@PStocIntrari
      
      select @CodIntrareIesiri=dbo.cautareCodIntrare(@Cod, @gest, @tipgest, 'NECORELP', @PStocIesiri, 0, @ContStoc, 0, 0, @datacorectii, @datacorectii, '', '', '', '', '', '')
      exec scriuAE @Numar=@nrcorectii, @Data=@datacorectii, @gest=@gest, @Cod=@Cod, @CodIntrare=@CodIntrareIesiri, 
            @Cantitate=1, @CtCoresp=@ctcorectii, @LM='', @Comanda='', @ComLivr='', @Explicatii='Corectii valoare stoc', 
            @Serie='', @Utilizator='CGplus', @Schimb=0, @Jurnal='', @Stare=5, @NrPozitie=null, @PozitieNoua=1, @PretStoc=@PStocIesiri
      
      fetch next from crsstoc into @gest, @tipgest, @Cod, @ValoareStoc
end
close crsstoc
deallocate crsstoc

end try
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
if object_id('tempdb..#docstoc') is not null drop table #docstoc
END
