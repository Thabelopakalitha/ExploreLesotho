// lib/screens/analytics/ai_insights_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

class AIInsightsDashboard extends StatelessWidget {
  const AIInsightsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.translate('AI-Powered Insights', 'Tlhahlobo ea AI'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            locale.translate(
              'Machine learning analysis of your platform data',
              'Tlhahlobo ea AI ea datha ea sethala sa hao',
            ),
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Booking Predictions
          _buildInsightCard(
            icon: Icons.trending_up,
            title:
                locale.translate('Booking Predictions', 'Diteko tsa Lipehelo'),
            value: '+23%',
            subtitle: locale.translate('Expected growth next month',
                'Kholo e lebelletsoeng khoeling e tlang'),
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          // Popular Times
          _buildInsightCard(
            icon: Icons.access_time,
            title: locale.translate(
                'Peak Booking Times', 'Dinako tsa Lipehelo tse Ngata'),
            value: '2-4 PM',
            subtitle: locale.translate('Most bookings occur in afternoon',
                'Lipehelo tse ngata li etsahala thapama'),
            color: Colors.orange,
          ),

          const SizedBox(height: 16),

          // Popular Destinations
          _buildInsightCard(
            icon: Icons.location_on,
            title: locale.translate('Top Destinations', 'Libaka tse Ratoang'),
            value: 'Semonkong, Malealea',
            subtitle: locale.translate(
                'Highest booking volume', 'Lipehelo tse ngata ka ho fetisisa'),
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          // Revenue Forecast
          _buildInsightCard(
            icon: Icons.attach_money,
            title: locale.translate('Revenue Forecast', 'Tekanyo ea Lekeno'),
            value: 'M245,000',
            subtitle: locale.translate(
                'Projected for next quarter', 'Tekanyo ea kotara e tlang'),
            color: Colors.purple,
          ),

          const SizedBox(height: 24),

          // Sentiment Analysis
          Text(
            locale.translate('Review Sentiment Analysis',
                'Tlhahlobo ea Maikutlo a Litlhahlobo'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSentimentBar(
                    label: locale.translate('Positive', 'E Ntle'),
                    percentage: 0.72,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildSentimentBar(
                    label: locale.translate('Neutral', 'E Bohareng'),
                    percentage: 0.18,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildSentimentBar(
                    label: locale.translate('Negative', 'E Mpe'),
                    percentage: 0.10,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recommendations
          Text(
            locale.translate('AI Recommendations', 'Dikgothatso tsa AI'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildRecommendationItem(
            title: locale.translate(
                'Increase marketing in Semonkong', 'Eketsa papatso Semonkong'),
            description: locale.translate('Booking demand up 45% in this area',
                'Lipehelo di eketsehile ka 45% sebakeng sena'),
          ),
          _buildRecommendationItem(
            title: locale.translate('Weekend promotions needed',
                'Dipapatso tsa mafelo-beke di a hlokahala'),
            description: locale.translate(
                'Weekend bookings are 30% lower than weekdays',
                'Lipehelo tsa mafelo-beke di tlase ka 30% ho feta matsatsi a beke'),
          ),
          _buildRecommendationItem(
            title: locale.translate('Add more adventure activities',
                'Kenya mesebetsi e mengata ya boithabiso'),
            description: locale.translate(
                'Adventure category has highest engagement',
                'Sehlopha sa boithabiso se na le tšebeliso e phahameng'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentBar({
    required String label,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(percentage * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem({
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.lightbulb, color: Colors.amber),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
