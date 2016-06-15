--***

Create  procedure spCopiereRamura @cTipSursa char(2), @cContractSursa char(20), @cTertSursa char(13), @cPozitieInitala int
	,@ctipDest char(2), @cContractDest char(20), @cTertDest char(13), @dDataDest datetime
as

Declare  @nFiu int,@cSub char(9), @nParinte int, @nrPoz int

exec luare_date_par 'GE','SUBPRO',0,0,@cSub output
Set @nParinte = isnull((Select max(parinte) from structcon where subunitate = @cSub and tip = @cTipSursa and contract = @cContractSursa and tert = @cTertSursa  and pozitie = @cPozitieInitala),0)




if @@nestlevel =  1 
begin
	exec sp_stergNodStruct @ctipDest ,@cContractDest , @cTertDest , @dDataDest , @cPozitieInitala

	Set @nrPoz = (select count(*) from structcon where  subunitate = @cSub and tip = @ctipDest and contract = @cContractDest and tert = @cTertDest)
	if @nrPoz = 0 
		begin
			insert into structcon (Subunitate,Tip,Contract,Tert,Data,Pozitie,Parinte,Text,Cantitate,Pret,Valoare)
			Values (@cSub,@cTipDest,@cContractDest,@cTertDest,@dDataDest,0,9999,'Contract '+rtrim(@cContractDest),0,0,0)
		end

	-- inserare prima linie (se modifica parintele in ROOT)
	insert into structcon
	(Subunitate,Tip,Contract,Tert,Data,Pozitie,Parinte,Text,Cantitate,Pret,Valoare)
	select Subunitate,@cTipDest,@cContractDest,@cTertDest,@dDataDest,Pozitie,0,Text,Cantitate,Pret,Valoare 
	from structcon where subunitate = @cSub and tip = @cTipSursa and contract = @cContractSursa and tert = @cTertSursa  and pozitie = @cPozitieInitala
end


--if @@nestlevel =  1 
--	begin
--		Delete from structcon where subunitate = @cSub and tip = @cTipDest and  contract = @cContractDest and tert = @cTertDest
--		Delete from pozcon  where subunitate = @cSub and tip = @cTipDest and  contract = @cContractDest and tert = @cTertDest
--		
--		--Inserare pozitie initiala (ROOT)		
--		insert into structcon (Subunitate,Tip,Contract,Tert,Data,Pozitie,Parinte,Text,Cantitate,Pret,Valoare)
--		Values (@cSub,@cTipDest,@cContractDest,@cTertDest,@dDataDest,0,9999,'Contract '+rtrim(@cContractDest),0,0,0)
--		--Select @cSub,@cTipDest,@cContractDest,@cTertDest,@dDataDest,@cPozitieInitala,9999,'Contract '+rtrim(@cContractDest),0,0,0
--
--		Update con set procent_penalizare = @nParinte where subunitate = @cSub and tip = @cTipDest and  contract = @cContractDest and tert = @cTertDest
--	end

else begin
	insert into structcon
	(Subunitate,Tip,Contract,Tert,Data,Pozitie,Parinte,Text,Cantitate,Pret,Valoare)

	select Subunitate,@cTipDest,@cContractDest,@cTertDest,@dDataDest,Pozitie,Parinte,Text,Cantitate,Pret,Valoare 
	from structcon
	where subunitate = @cSub and tip = @cTipSursa and contract = @cContractSursa and tert = @cTertSursa  and pozitie = @cPozitieInitala
end

if exists (select * from pozcon where tip = @cTipSursa and contract = @cContractSursa and tert = @cTertSursa  and pret_promotional = @cPozitieInitala)
begin
	insert into pozcon
	(Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Cod,Cantitate,Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,Data_operarii,Ora_operarii)

	select Subunitate,@cTipDest,@cContractDest,@cTertDest,Punct_livrare,@dDataDest,Cod,Cantitate,Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,Data_operarii,Ora_operarii
	from pozcon where subunitate = @cSub and tip = @cTipSursa and contract = @cContractSursa and tert = @cTertSursa  and pret_promotional = @cPozitieInitala
	return
end

Declare @tmpPozCrs cursor
Set @tmpPozCrs = cursor for
select pozitie from structcon where subunitate = @cSub and tip = @cTipSursa and contract = @cContractSursa and tert = @cTertSursa and parinte = @cPozitieInitala
open @tmpPozCrs
fetch next from @tmpPozCrs into @nFiu
while @@fetch_status = 0
begin
	exec spCopiereRamura  @cTipSursa, @cContractSursa, @cTertSursa , @nFiu , @ctipDest , @cContractDest , @cTertDest , @dDataDest 
	fetch next from @tmpPozCrs into @nFiu
end
close @tmpPozCrs
deallocate @tmpPozCrs
