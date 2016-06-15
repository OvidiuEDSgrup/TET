--***
/**	functie ce returneaza vechimea in format AA/LL/ZZ 
	este nevoie de functie intrucat la salariatii fara vechime in ASiS vechimea are data de 1899 
	este nevoie in mai multe locuri de aceasta vechime */
Create function fVechimeAALLZZ(@vechime datetime)
returns varchar(8)
as
begin
	return 
		(case when (case when year(@vechime)=1899 then 1900 else year(@vechime)+(case when month(@vechime)=12 then 1 else 0 end) end)-1900<10 then '0' else '' end)
			+rtrim(convert(char(2),(case when year(@vechime)=1899 then 1900 else year(@vechime)+(case when month(@vechime)=12 then 1 else 0 end) end)-1900))
			+'/'+(case when month(@vechime)=12 or month(@vechime)<10 then '0' else '' end)+rtrim(CONVERT(char(2),(case when month(@vechime)=12 then 0 else month(@vechime) end)))
			+'/'+(case when day(@vechime)<10 then '0' else '' end)+rtrim(convert(char(2),day(@vechime)))
end
