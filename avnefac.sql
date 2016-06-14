Select * from ASiSRIA..sesiuniRIA
alter table avnefac alter column Terminal varchar(25)
drop index principal on avnefac
create unique clustered index Principal on avnefac (Terminal, Subunitate, Tip, Numar, Cod_gestiune, Data, Contractul) 