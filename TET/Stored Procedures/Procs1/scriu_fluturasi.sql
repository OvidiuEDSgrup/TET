--***
/**	procedura scriu fluturasi	*/
Create procedure scriu_fluturasi
	@HostID char(10), @marca char(6), @Tip char(1), @denumire char(50), @ore_procent char(20), @valoare float, @Conditie1 int, @Conditie2 int,@Conditie3 int, @cand_scriu int, @Tip_suma char(1)
As
declare @flut1col bit, @flut1col_cuseparatori int, @gTip_suma char(1), @Contor_tip_suma int, @Contor_marca int
--Variabila pusa pe True din procedura din formularul SQL,pt. a putea scrie din formularul sql pt. Colas in tabela flutur datele pe o singura col
Exec Luare_date_par 'PS', 'FLUT_1CL', @flut1col output , @flut1col_cuseparatori output, 0
Set @gTip_Suma = (case when @flut1col=1 then @tip_suma else '' end)
Set @Contor_tip_suma = 0
if @flut1col=1
Begin
	Set @Contor_tip_suma = isnull((select max(nr_linie) from flutur where Hostid=@HostID and marca_i=@marca and Marca_p=@Tip_suma),0)
	Set @Contor_tip_suma = @Contor_tip_suma + 1
End

if (@Conditie1=1 or @flut1col=1) and (@cand_scriu=1 or @valoare<>0) and not(@flut1col=1 and @flut1col_cuseparatori=0 and (left(@denumire,2)='--' or left(@denumire,6)='PLATIT'))
Begin
	Set @Contor_marca = (select contor_marca from #contor_marca)
	Set @Contor_marca = @Contor_marca+1
	update #contor_marca set contor_marca=@Contor_marca
	insert into flutur (HostID, Numar_pozitie, Tip_form, Marca_i, Text_i, Ore_procent_i, Valoare_i, Marca_p, Text_p, Ore_procent_p, Valoare_p, Marca, Text, Ore_procent, Valoare, Nr_linie) 
	select @HostID, @Contor_marca, @tip, @marca, @denumire, ltrim(@ore_procent), @valoare, @gTip_Suma , '', '', 0, '', '', '', 0, @Contor_tip_suma 
End
If @flut1col=0 
Begin 
	if @Conditie2=1 and (@cand_scriu=1 or @valoare<>0) 
	Begin
		Set @Contor_marca = (select contor_marca from #contor_marca)
		Set @Contor_marca = @Contor_marca+1
		update #contor_marca set contor_marca=@Contor_marca
		if exists (select numar_pozitie from flutur where numar_pozitie = @Contor_marca) 
			update flutur set marca_p=@marca, text_p=@denumire, ore_procent_p=ltrim(@ore_procent), valoare_p=@valoare 
			where HostID=@HostID and numar_pozitie=@Contor_marca
		else  
			insert into flutur (HostID, Numar_pozitie, Tip_form, Marca_i, Text_i, Ore_procent_i, Valoare_i, Marca_p, Text_p, Ore_procent_p,	Valoare_p, Marca, Text, Ore_procent, Valoare, Nr_linie)
			select @HostID, @Contor_marca, @tip, '', '', '', 0, @marca, @denumire, ltrim(@ore_procent), @valoare, '', '', '', 0, 0
	End
	If @Conditie3=1 and (@cand_scriu=1 or @valoare<>0)
	Begin
		Set @Contor_marca = (select contor_marca from #contor_marca)
		Set @Contor_marca = @Contor_marca+1
		update #contor_marca set contor_marca=@Contor_marca
		if exists (select numar_pozitie from flutur where numar_pozitie = @Contor_marca) 
			update flutur set marca=@marca, text=@denumire, ore_procent=ltrim(@ore_procent), valoare=@valoare 
			where HostID=@HostID and numar_pozitie=@Contor_marca
		else  
			insert into flutur (HostID, Numar_pozitie, Tip_form, Marca_i, Text_i, Ore_procent_i, Valoare_i, Marca_p, Text_p, Ore_procent_p, Valoare_p, Marca, Text, Ore_procent, Valoare, Nr_linie)
			select @HostID, @Contor_marca, @tip, '', '', '', 0,'', '', '', 0, @marca, @denumire, ltrim(@ore_procent), @valoare, 0
	End
End
