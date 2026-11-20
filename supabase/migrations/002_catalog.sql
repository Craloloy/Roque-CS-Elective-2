-- Initial catalog. Run once after 001; repeat runs skip existing names.
begin;
insert into magistore.categories(name) values
('Books'),
('Course Pins'),
('ID Accessories'),
('PE Uniforms'),
('Pins & Ribbons'),
('Study Supplies')
on conflict do nothing;
with seed(name,category,price,stock,description,image_url) as (values
('Ateneo University Pin', 'Pins & Ribbons', 150, 24, 'A classic university pin: a scalloped gold edge, dark blue enamel ring, and Ateneo de Davao crest. A butterfly clutch secures the reverse. Gold-tone metal · Blue enamel · Butterfly clasp', 'assets/products/pin-reference.png'),
('University ID Sling', 'ID Accessories', 120, 18, 'Keep your campus essentials close. A comfortable woven lanyard with a secure metal clasp. Navy woven strap · White university lettering · Black quick-release buckle · Silver hook', 'assets/products/sling-reference.png'),
('PE Uniform · Round Neck', 'PE Uniforms', 850, 30, 'A comfortable PE set for male and female students: a white round-neck shirt with blue sleeve edging, a small P.E. crest, and full-length navy pants. White round-neck shirt · Blue sleeve trim · Navy full-length pants · Vertical ATENEO leg print', 'assets/products/uniform-reference.png'),
('Nursing Caduceus Pin', 'Course Pins', 180, 0, 'A meaningful detail for your nursing journey. A sculpted gold-tone caduceus with a secure pin backing. Gold-tone alloy · Polished finish · Secure backing', 'assets/products/caduceus-reference.png'),
('Clear Landscape ID Case', 'ID Accessories', 95, 5, 'A clean, durable home for your Ateneo ID. Designed to pair with your favorite university sling. Clear landscape holder · Silver-tone rivets · Upper attachment point', 'assets/products/case-reference.png'),
('Plain Navy Ribbon', 'Pins & Ribbons', 65, 30, 'A simple navy ribbon for your campus essentials. A simple unprinted woven band, distinct from the university ID sling. Plain navy woven band · Unprinted finish · Flat ends', 'assets/products/ribbon-reference.png'),
('PE Uniform · Collared', 'PE Uniforms', 900, 22, 'A classic collared PE set for male and female students. A white polo with a blue collar and sleeve trim, paired with full-length navy Ateneo pants. Blue fold-over collar · Small chest P.E. crest · White shirt · Navy long pants', 'assets/products/polo-reference.png'),
('Dart Apprentice: Fundamentals', 'Books', 349, 18, 'A beginner’s guide to Dart by Jonathan Sande and the Kodeco Tutorial Team. First edition · Dart programming', 'assets/products/study-dart-guide.webp'),
('Introduction to Algorithms', 'Books', 495, 14, 'The fourth edition by Cormen, Leiserson, Rivest, and Stein covers algorithm design and analysis. Fourth edition · MIT Press', 'assets/products/study-algorithms-guide.webp'),
('Discrete Mathematics and Its Applications', 'Books', 395, 12, 'Kenneth H. Rosen’s textbook covers logic, sets, counting, and graph theory. Eighth edition · McGraw Hill', 'assets/products/study-discrete-guide.webp'),
('The Craft of Research', 'Books', 325, 15, 'A guide to developing research questions, working with sources, and making evidence-based arguments. Fifth edition · University of Chicago Press', 'assets/products/study-research-guide.webp'),
('MUJI A5 Grid Notebook', 'Study Supplies', 95, 27, 'A grid notebook for diagrams, equations, and everyday lecture notes. A5 · Grid paper', 'assets/products/study-grid-notebook.webp'),
('Post-it Pastel Index Flags', 'Study Supplies', 55, 24, 'Mark chapters and important sections without covering the text. Five colors · Repositionable tabs', 'assets/products/study-index-tabs.webp'),
('Staedtler Pigment Liner Set', 'Study Supplies', 119, 22, 'Three fine tip pens for annotations, diagrams, and margin notes. Black pigment ink · Three pens', 'assets/products/study-pen-set.webp'),
('Kokuyo Ring-Bound Flash Cards', 'Study Supplies', 79, 20, 'Make your own quizzes for formulas, definitions, and key terms. Blank study cards · Binder ring', 'assets/products/study-study-cards.webp'))
insert into magistore.products(name,category_id,price,stock,description,image_url)
select s.name,c.id,s.price,s.stock,s.description,s.image_url from seed s join magistore.categories c on c.name=s.category
where not exists (select 1 from magistore.products p where p.name=s.name);
commit;
