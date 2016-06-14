select * -- update t set inlocuiesc='Nu'
from yso_TabInl t where t.Tip=-2 and t.Inlocuiesc='Da' and t.Denumire_SQL not in ('bp','antetbonuri')