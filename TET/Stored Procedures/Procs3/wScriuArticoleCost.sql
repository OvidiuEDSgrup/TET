--***
create procedure wScriuArticoleCost @sesiune varchar(50),@parXML xml
as 
declare @mesaj varchar(254), @art_cost varchar(9), @ordinea_in_raport int, @denumire varchar(40),
	@grup bit, @baza_rl bit, @baza_rg bit, @baza_ch_ap bit, @baza_ch_des bit, @update int

select @art_cost=isnull(@parXML.value('(/row/@art_cost)[1]','varchar(9)'),''),
	@update=isnull(@parXML.value('(/row/@update)[1]','int'),0),
	@denumire=isnull(@parXML.value('(/row/@denumire)[1]','varchar(40)'),''),
	@ordinea_in_raport=isnull(@parXML.value('(/row/@ordinea_in_raport)[1]','int'),0),
	@grup=isnull(@parXML.value('(/row/@grup)[1]','int'),0),
	@baza_rl=isnull(@parXML.value('(/row/@baza_rl)[1]','int'),0),
	@baza_rg=isnull(@parXML.value('(/row/@baza_rg)[1]','int'),0),
	@baza_ch_ap=isnull(@parXML.value('(/row/@baza_ch_ap)[1]','int'),0),
	@baza_ch_des=isnull(@parXML.value('(/row/@baza_ch_des)[1]','int'),0)

begin try
	if @art_cost in ('L','G') and @baza_rl=1
		raiserror('Articolele de calculatie L si G nu pot fi baza de repartizare pentru regie sectie!',11,1)

	if @art_cost in ('G') and @baza_rl=1
		raiserror('Articolul de calculatie G nu poate fi baza de repartizare pentru regie generala!',11,1)

	if @update=1 
	begin  
		update artcalc set denumire=@denumire, Ordinea_in_raport=@Ordinea_in_raport, grup=@grup, baza_pt_regia_sectiei=@baza_rl,
			Baza_pt_regia_generala=@baza_rg, Baza_pt_ch_aprovizionare=@baza_ch_ap, Baza_pt_ch_desfacere=@baza_ch_des
		where articol_de_calculatie=@art_cost
	end
	else   
	begin 
		if exists(select 1 from artcalc where articol_de_calculatie=@art_cost)
			raiserror ('Aceasta articol de calculatie a fost deja introdus!',11,1)
		else			 
			insert into artcalc (Articol_de_calculatie, Ordinea_in_raport, Denumire, Grup, Baza_pt_regia_sectiei, Baza_pt_regia_generala, Baza_pt_ch_aprovizionare, Baza_pt_ch_desfacere)  
			values (@art_cost,@ordinea_in_raport,@denumire,@grup,@baza_rl,@baza_rg,@baza_ch_ap,@baza_ch_des)  
	end  
end try
begin catch
	set @mesaj = '(wScriuArticoleCost:) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
  /*
  sp_help artcalc
  */ 
