--***
/**	procedura scriuAvexcep	*/
Create 
procedure scriuAvexcep (@Data datetime,@Marca char(6),@Ore_lucrate_la_avans int,@Suma_avans float,@Premiu_la_avans float)
As
Begin 
	If isnull((select count(1) from avexcep where Data=@Data and Marca=@Marca),0)=1
		update avexcep set Ore_lucrate_la_avans=@Ore_lucrate_la_avans, 
		Suma_avans=@Suma_avans, Premiu_la_avans=@Premiu_la_avans
		where Marca=@Marca and Data=@Data
	Else 
		insert into avexcep (Marca, Data, Ore_lucrate_la_avans, Suma_avans, Premiu_la_avans)
		Select @Marca, @Data, @Ore_lucrate_la_avans, @Suma_avans, @Premiu_la_avans
End
